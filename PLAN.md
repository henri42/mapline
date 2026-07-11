# Mapline — Plan de construction du MVP

## Contexte

Mapline est une application web (greenfield, dépôt vide hormis `IDEE.md`) permettant aux amateurs d'histoire — historiens, politologues, journalistes, enseignants — de créer des cartes historiques/géopolitiques qui évoluent dans le temps, couplées à une frise chronologique navigable. Le lecteur déplace un curseur sur la frise de date clé en date clé et la carte s'anime en conséquence.

### Décisions prises avec l'utilisateur
- **Périmètre MVP** : éditeur + lecture publique (comptes auteurs, éditeur carte+frise, pages publiques, profils, sources obligatoires, statuts brouillon/privée/publique).
- **Carto client** : MapLibre GL JS.
- **Modèle temporel** : **géométries versionnées** — un même élément (ex. un royaume) peut changer de forme à chaque date clé, avec transition animée.
- **Fond de carte** : neutre, sans frontières ni toponymes actuels (tuiles vectorielles OpenFreeMap, style custom).

### Contraintes techniques
- Rails 8.0.4 / Ruby 4.0.1, défauts Rails 8 au maximum (SQLite, Solid Queue/Cache/Cable, générateur d'authentification, Propshaft).
- Vues serveur en Phlex (`phlex-rails`), JS client en Stimulus + Turbo via `vite_rails` (Node 26).
- Interface simple et moderne, micro-animations ponctuelles.

## Décisions d'architecture transverses

### Pas de PostGIS en v1 — GeoJSON en colonnes JSON
- « Défauts Rails 8 » ⇒ SQLite ; PostGIS imposerait PostgreSQL et casserait la stack Solid* sur SQLite.
- Aucune requête spatiale en v1 : les géométries sont des blobs que le serveur stocke et resert ; tout le travail géométrique est client.
- Validation serveur légère : `GeojsonValidator` maison (type autorisé, coordonnées bornées [-180,180]/[-90,90], taille max ~500 Ko). Pas de RGeo.
- Porte de sortie future : migration PostgreSQL+PostGIS, import trivial via `ST_GeomFromGeoJSON`.

### Dates historiques (les types `date` SQL sont inadaptés : années négatives, granularité)
- `year:integer` signé en **numérotation astronomique** (0 = 1 av. J.-C., -752 = 753 av. J.-C.) — tri et arithmétique triviaux ; helper d'affichage `year <= 0 ? "#{1 - year} av. J.-C." : year`.
- `month` (1..12) et `day` nullables ; la granularité est dérivée de la nullabilité (pas de colonne `precision`).
- `sort_key:integer` calculé en `before_validation` : `year * 10_000 + (month || 1) * 100 + (day || 1)` — correct aussi pour les années négatives. Index unique `(mapline_id, sort_key)`.
- `label:string` nullable : libellé libre (« vers 800 ») qui prime sur le rendu automatique — gère les dates incertaines.

## Modèle de données

### `users` (générateur d'authentification Rails 8) + profil
Colonnes du générateur (`email_address`, `password_digest`, table `sessions`) + profil directement sur `users` : `display_name` (null: false), `bio:text`, `website_url`, `slug` (index unique). Écran d'inscription à ajouter (le générateur ne fournit que la connexion).

### `maplines`
- `user_id`, `title` (null: false), `slug` (index unique, `parameterize` + suffixe aléatoire — pas de gem), `description:text`
- `status:string` enum : `draft` (auteur seul) / `unlisted` (accessible par lien) / `public` (listée) — default `draft`
- Vue initiale : `center_lng:float`, `center_lat:float`, `zoom:float` (defaults vue monde), `published_at:datetime`
- Validations au contexte `:publish` (pas à la création) : ≥ 1 source, ≥ 1 date clé.

### `key_dates` (dates clés de la frise)
`mapline_id`, `year`, `month`, `day`, `sort_key` (voir ci-dessus), `label`, `title` (ex. « Congrès de Vienne »), `description:text`. **Date ponctuelle, pas période** : une période = deux dates clés successives. Une date clé = un « chapitre » = l'unité de versionnement des géométries.

### `map_features` (éléments cartographiques — identité stable dans le temps)
`mapline_id`, `feature_type` enum (`area`, `line`, `arrow`, `point`, `label`), `name` (« Royaume de France »), `z_index:integer`, `style:json` (fill, fillOpacity, stroke, strokeWidth, strokeDash, icon, textSize).

### `feature_states` — versionnement, cœur du système
**Modèle « états épars + report en avant » (carry-forward)** : un état par couple (feature, date clé) *uniquement quand quelque chose change*.
- `map_feature_id`, `key_date_id`, index unique sur le couple
- `geometry:json` (GeoJSON : Polygon/MultiPolygon pour `area`, LineString pour `line`/`arrow`, Point pour `point`/`label`)
- `style_override:json` nullable (fusion `feature.style.merge(override)`)
- `visible:boolean` default true — `false` = disparition explicite (destruction d'un royaume sans supprimer la feature)

**Règle de résolution** : l'état d'une feature à la date D = le state dont `key_date.sort_key` est le plus grand ≤ D ; aucun state ≤ D ⇒ feature non affichée (permet l'apparition en cours de frise). Implémentée deux fois : POJO Ruby `StateResolver` (sérialisation, tests) et miroir JS côté client (payload minimal, données éparses).

### `events`
- `mapline_id`, `key_date_id` (null: false, date de début ancrée sur la frise), `end_key_date_id` (nullable, `foreign_key: { to_table: :key_dates }` — période)
- `title` (null: false), `description:text`
- Localisation, au plus un des deux : `longitude`+`latitude` (marqueur ponctuel) **ou** `map_feature_id` (surbrillance d'une zone)
- `event_links` : `event_id`, `label`, `url` (null: false, format validé), `position` — liens externes (JTBD journaliste).

### `sources`
`mapline_id`, `title` (null: false), `url`, `author`, `position`. Obligation portée par la transition de publication (contexte `:publish`), pas par la création.

## Architecture front de l'éditeur

- **Store JS central** (`app/frontend/editor/store.js`, ~100 lignes, pas de framework) : état (features, states, dates clés, date courante, sélection, statut de sauvegarde) + pub/sub minimal + `resolveStateAt(feature, sortKey)` (miroir du `StateResolver` Ruby).
- **Contrôleurs Stimulus = liaison DOM uniquement**, tous branchés sur le store (pas d'outlets en cascade) : `editor--map` (MapLibre + Terra Draw), `editor--timeline`, `editor--toolbar` (mode de dessin), `editor--features-panel` (liste + badges d'héritage), `editor--inspector` (style/nom), `editor--autosave` (indicateur). Payload initial embarqué dans un `<script type="application/json">`.
- **Persistance hybride** :
  - Endpoints JSON (namespace `Editor::`) pour le canevas : `POST/PATCH/DELETE features`, `PUT/DELETE /editor/features/:id/states/:key_date_id` (upsert idempotent), `PATCH mapline` (vue initiale, titre).
  - Turbo Frames/Streams + Phlex pour les formulaires : dates clés, événements, sources, réglages.
  - **Autosave** : debounce 800 ms après chaque fin d'édition Terra Draw, statut optimiste. Pas de lock optimiste en v1 (mono-auteur).
- **Outil de dessin : Terra Draw** (+ `terra-draw-maplibre-gl-adapter`) — activement maintenu, adaptateur MapLibre officiel, cité dans la doc MapLibre ; mapbox-gl-draw est en quasi-gel et pensé pour Mapbox GL. Flèches = LineString + pointe rendue en couche `symbol` orientée selon le dernier segment ; étiquettes = point + texte en couche `symbol`.
- **UX des géométries versionnées** :
  1. Sélection d'une date clé ⇒ la carte affiche l'état résolu (héritage appliqué).
  2. Badge par feature : « état défini ici » / « hérité de {date} » / « pas encore apparu ».
  3. **Modifier une feature héritée crée automatiquement un état à la date courante** (duplication de la géométrie héritée) + toast avec « Annuler ».
  4. Actions explicites : « Créer un état ici », « Supprimer l'état (revenir à l'héritage) », « Masquer à partir d'ici », « Réafficher ».
  5. Terra Draw ne porte que la feature en cours d'édition ; le reste est rendu en couches MapLibre normales.

## Rendu lecteur + animation

- Page publique Phlex, payload JSON complet embarqué (cacheable en fragment) ; résolution carry-forward côté client.
- Quatre sources GeoJSON (areas, lines/arrows, points, labels) + couches associées, styles en propriétés de features (`["get", "fill"]`). Changement de date = `source.setData()`.
- **Transitions : cross-fade en v1** (deux jeux de sources entrant/sortant, transitions de paint properties MapLibre ~400 ms — robuste à tous les cas : scission, fusion, apparition). **Morphing flubber en v2 opt-in** par feature avec repli automatique cross-fade (turf.js ne fait pas de morphing — écarté).
- **Frise : composant Stimulus custom partagé éditeur/lecteur** (vis-timeline/TimelineJS trop lourds pour ce besoin). Piste horizontale, graduations = dates clés, **espacement uniforme en v1** ; clic, glisser avec aimantation, flèches clavier, boutons préc./suiv. ; titre+description de la date courante ; micro-animations (curseur spring, pulse discret).

## Jalons (chacun démontrable)

> **Avancement** : M0, M1, M2, M3, M4 réalisés. Prochain : M5.
> Chaque jalon fait est suivi d'une note **→ Réalisé** consignant les écarts au plan.

### M0 — Socle : app qui tourne, auth, layout Phlex ✅
```bash
rails new . --skip-javascript
bundle add vite_rails phlex-rails
bundle exec vite install
bin/rails generate phlex:install
bin/rails generate authentication
npm add @hotwired/turbo @hotwired/stimulus stimulus-vite-helpers
```
Layout Phlex, enregistrement auto des contrôleurs Stimulus (`stimulus-vite-helpers`), migration profil users, écran d'inscription.

**→ Réalisé.** Écart assumé : **Tailwind CSS v4** adopté (`@tailwindcss/vite`) plutôt que du CSS maison sans framework. Les design tokens vivent dans le bloc `@theme` de `app/frontend/styles/application.css` (ils deviennent des utilitaires `bg-canvas`, `text-muted`…), les classes réutilisables `.btn`/`.field` sous `@layer components`. Les vues Phlex étant hors du root Vite, elles sont déclarées comme sources Tailwind via `@source "../../views"` / `"../../components"`.

### M1 — CRUD Maplines + statuts + sources + profils ✅
Modèles `Mapline` et `Source`, tableau de bord auteur, machine à statuts avec validation `:publish`, page publique `/m/:slug` (contrôle d'accès par statut), profil `/@:slug`, sources en Turbo Frames imbriquées.

**→ Réalisé.** Notes :
- **Module applicatif renommé `Mapline` → `MaplineApp`** (`config/application.rb`) : le nom `Mapline` du module Rails masquait la constante du modèle `Mapline` sous Zeitwerk. Ne pas rétablir.
- Enum `status` déclaré avec `scopes: false` (un scope `Mapline.public` écraserait `Module#public`) ; scopes maison `listed` / `accessible_by_link`. Transition via `publish_as(status)` ; validation `:publish` = ≥ 1 source pour l'instant (le ≥ 1 date clé viendra avec M3).
- Sources en **frames imbriqués tout-redirection** : frame externe `sources_manager` (liste + formulaire d'ajout ; create/delete le rechargent) et frames internes `source_<id>` pour l'édition en ligne. Pas de `turbo_stream` custom.
- **Refactor kit Phlex** : composants `Button`/`Link` appelés via le kit (`Button(...)`, `Link(...)`) avec argument `variant` (`:primary`/`:ghost`/`:danger`), mapping variante→CSS centralisé dans `Components::Base#button_classes`.

### M2 — Carte statique + fond neutre + vue initiale ✅
`npm add maplibre-gl`. Style JSON custom dans le repo à partir du style Positron d'OpenFreeMap (gratuit, sans clé) : suppression des couches `boundary`, `place`, `poi`, noms de routes (schéma OpenMapTiles). Relief hillshade optionnel (AWS Terrain) — à valider ici, sinon repli sans relief. Bouton « Définir la vue initiale ».

**→ Réalisé.** Notes :
- `app/frontend/styles/basemap-neutral.json` : style **minimal écrit à la main** (source vectorielle OpenFreeMap `openmaptiles`, couches `background`/`water`/`waterway`/`park`/`landcover_wood` uniquement) plutôt que Positron dépouillé — même résultat neutre, plus maintenable. Ni frontières, ni toponymes, ni routes.
- **Relief hillshade écarté en v1** (repli assumé) : le raster ombré OpenFreeMap plafonne à z6 et bavouille en surzoom.
- Contrôleur Stimulus `map` (`app/frontend/controllers/map_controller.js`) partagé lecteur/éditeur. Le bouton « Définir la vue initiale » enregistre centre/zoom via `PATCH /maplines/:id.json` — `MaplinesController#update` répond en HTML **et** JSON (préfigure les endpoints `Editor::` de M4).
- CSP toujours désactivée (initializer commenté), d'où l'accès direct aux tuiles OpenFreeMap et aux web workers blob de MapLibre.

### M3 — Dates clés + frise ✅
Modèle `KeyDate` avec `sort_key` + **tests dédiés dates négatives/granularité**, CRUD en Turbo Frames (champs année / av.-ap. J.-C. / mois / jour), composant frise partagé.

**→ Réalisé.** Notes :
- **Saisie via attributs virtuels `year_input` + `era`** (année positive + av./ap. J.-C.) convertis en `year` astronomique signé dans un `before_validation` ; `sort_key` calculé dans un second `before_validation`. Helper `display_date` : `label` prime, sinon rendu selon la granularité (jour+mois+année / mois+année / année) avec suffixe « av. J.-C. ». Un helper privé `effective_year` fait fonctionner l'affichage même avant validation (dérive de la saisie), utilisé par les tests sur enregistrements `.new`.
- Validations en **erreurs sur `:base`** (messages français propres, sans préfixe d'attribut anglais — pas de locale fr installée), calquées sur `Mapline#must_have_a_source`. Unicité `(mapline_id, sort_key)` doublée d'un index unique en base.
- **Prérequis de publication complété** : `Mapline` valide désormais ≥ 1 source **et** ≥ 1 date clé au contexte `:publish` (le second était annoncé pour M3 dans la note M1).
- **CRUD en frames imbriqués tout-redirection**, strictement calqué sur les sources : frame externe `key_dates_manager`, frames internes `key_date_<id>`. `KeyDatesController` sous `resources :maplines`.
- **Composant frise partagé** `Components::Timeline` (kit Phlex) + `timeline_controller.js` (Stimulus), rendu **à la fois éditeur** (aperçu sous le gestionnaire) **et lecteur** (page publique). Espacement uniforme v1 ; clic, glisser avec aimantation, flèches clavier, boutons préc./suiv. ; panneau date+titre+description. Les données de chaque date sont portées par les graduations en `data-*` (pas de blob JSON). À chaque changement, émet `timeline:change` (`{ index, sortKey, keyDateId }`) que la carte consommera à partir de M5.
- **Écart assumé** : le gestionnaire de dates clés construit une date vierge (formulaire d'ajout) qui pollue l'association en mémoire ; l'aperçu de la frise filtre donc sur `persisted?`.

### M4 — Dessin d'éléments (mono-état) : dessiner une carte statique complète ✅
`npm add terra-draw terra-draw-maplibre-gl-adapter`. Modèles `MapFeature`/`FeatureState`, store éditeur, toolbar, intégration Terra Draw, inspecteur de style, endpoints JSON, `GeojsonValidator`, autosave. Tout état rattaché à la première date clé à ce stade.

**→ Réalisé.** Notes :
- **Modèles** `MapFeature` (enum `feature_type`, `style:json`, `resolved_style` = défauts du type fusionnés) et `FeatureState` (`geometry:json`, `style_override`, `visible`, unicité `(map_feature_id, key_date_id)`). Contrôle croisé type géométrie ↔ type de feature dans `FeatureState`, plus garde « la date clé appartient à la même carte ».
- **`GeojsonValidator`** (`app/validators/`, `ActiveModel::EachValidator`) : type autorisé (Point/LineString/Polygon/MultiPolygon), coordonnées bornées, taille ≤ 500 Ko. `validates :geometry, geojson: true`.
- **Endpoints JSON** sous `namespace :editor` : `Editor::FeaturesController` (create imbriqué sous mapline avec premier état transactionnel, update, destroy) et `Editor::FeatureStatesController` (upsert PUT idempotent `/editor/features/:id/states/:key_date_id`, destroy). `Editor::BaseController` charge via `Current.user.maplines` (accès croisé → 404) et délègue la sérialisation à **`EditorPayload`** (source unique du JSON éditeur, réutilisée par la vue et les endpoints ; `feature_json` renvoie le **style résolu** pour un rendu client direct).
- **Store JS singleton** (`app/frontend/editor/store.js`) hydraté une fois depuis `#editor-payload`, pub/sub, `resolveState` (mono-état en M4). `editor/api.js` (fetch CSRF), `editor/layers.js` (4 sources GeoJSON + têtes de flèches calculées, styles pilotés par propriétés).
- **Contrôleurs Stimulus** `editor--map` (MapLibre + Terra Draw, dessin → create, sélection au clic, autosave géométrie via édition Terra Draw en mode select, bouton « vue initiale » repris de M2), `editor--toolbar`, `editor--features-panel`, `editor--inspector` (champs nom/style dynamiques par type, debounce), `editor--autosave` — tous branchés sur le store (pas d'outlets). Commandes impératives carte via `CustomEvent('editor:map-command')`.
- **Fond de carte** : ajout d'une URL `glyphs` (OpenFreeMap) au style neutre pour les couches symbol (étiquettes, têtes de flèches).
- **Écart assumé** : l'éditeur remplace la carte « Vue initiale » de M2 sur la page edit (une seule carte MapLibre) ; le contrôleur `map` de M2 ne sert plus que la page lecteur.
- **Vérification** : tests modèles (validateur, cohérence géométrie, unicité), intégration des endpoints (auth, rejets validateur, upsert idempotent), et **test système pilotant l'éditeur dans un vrai navigateur** (dessin d'un point → persistance → rechargement → suppression). Config test système : WebGL logiciel SwiftShader activé pour MapLibre en headless.

### M5 — Versionnement des géométries : la carte évolue au fil de la frise (cut sec)
`StateResolver` Ruby + miroir JS, sérialiseur du payload lecteur, badges héritage, duplication auto au premier trait, actions supprimer/masquer/réafficher, rendu lecteur résolu par date.

### M6 — Animation + événements = **MVP complet**
Cross-fade entre états, modèles `Event`/`EventLink` (migration manuelle pour `end_key_date_id`), panneau événements + marqueurs/surbrillance, CRUD événements (Turbo), seeds d'une carte d'exemple soignée (ex. guerres napoléoniennes).

### M7 — Polish (post-MVP, à la carte)
Morphing flubber opt-in, pelure d'oignon dans l'éditeur, View Transitions sur navigations Turbo, page d'accueil vitrine, OG images, `turf.simplify` à la sauvegarde si payloads lourds.

## Risques et mitigations

| Risque | Mitigation |
|---|---|
| Morphing de polygones (topologie changeante) | Cross-fade par défaut en v1 ; flubber opt-in avec repli auto ; ne pas le promettre dans le MVP |
| État de l'éditeur en spaghetti avec Stimulus seul | Store central unique, contrôleurs réduits à la liaison DOM, contrat d'événements documenté dès M4 |
| Carry-forward mal compris (« ma modif de 1815 change 1870 ?! ») | Badges héritage explicites, toast à la duplication auto, test avec un vrai scénario historique dès M5 |
| Fond « neutre » laissant passer des toponymes ; côtes modernes sur cartes antiques | Revue exhaustive des couches OpenMapTiles à M2 ; limitation côtes assumée ; repli Protomaps (PMTiles auto-hébergées) |
| Dates av. J.-C. | Numérotation astronomique + `sort_key`, tests unitaires dédiés dès M3, helper d'affichage centralisé |
| Géométries lourdes en JSON/SQLite | Limite de taille validée serveur, simplify optionnel, cache fragment du payload |
| Écosystème récent (Phlex 2, Terra Draw 1, vite_rails/Rails 8) | Compatibilités vérifiées ; versions verrouillées ; une brique par jalon pour isoler les frictions |
| Suppression d'une date clé portant des états | `dependent: :destroy` + confirmation listant les états impactés |

## Vérification

- À chaque jalon : `bin/dev` (Rails + Vite), démo manuelle du critère du jalon dans le navigateur.
- Tests Rails (Minitest, défaut) : modèles (dates négatives, `sort_key`, résolution `StateResolver`, validations `:publish`, `GeojsonValidator`), contrôleurs des endpoints JSON éditeur, contrôle d'accès par statut.
- Scénario de bout en bout à M6 avec les seeds : créer une carte, 3 dates clés, un royaume dont la frontière change, un événement ; publier ; vérifier la navigation lecteur (frise, transitions, panneau événements) et l'accès selon le statut.

## Fichiers critiques (à créer)
- `app/models/feature_state.rb` + `app/models/state_resolver.rb` — cœur du versionnement
- `app/models/key_date.rb` — dates historiques (année astronomique, `sort_key`)
- `app/frontend/editor/store.js` — état central de l'éditeur, pivot des contrôleurs Stimulus
- `app/frontend/controllers/editor/map_controller.js` — MapLibre + Terra Draw
- `app/frontend/controllers/reader/map_controller.js` — rendu lecteur + transitions
- `app/frontend/styles/basemap-neutral.json` — style de fond custom sans frontières
