# Mapline

Mapline permet aux amateurs d'histoire de créer des cartes historiques et
géopolitiques qui évoluent dans le temps, couplées à une frise chronologique
navigable : le lecteur déplace un curseur de date en date et la carte s'anime
en conséquence.

Voir `PLAN.md` pour l'architecture et la feuille de route (jalons M0–M7), et
`IDEE.md` pour le brief d'origine.

## Stack

Rails 8.0 / Ruby 4.0, défauts Rails 8 (SQLite, Solid Queue/Cache/Cable,
Propshaft, authentification maison). Vues serveur en Phlex, JS client en
Stimulus + Turbo via Vite. Styling Tailwind CSS v4. Cartographie MapLibre GL
JS (tuiles vectorielles OpenFreeMap, fond neutre sans frontières/toponymes).

## Installation

```bash
bin/setup        # installe les dépendances Ruby et JS, prépare la base
```

## Lancer l'application

```bash
bin/dev           # serveurs Rails + Vite (via Procfile.dev / Foreman)
```

## Tests

```bash
bin/rails test              # suite Minitest (modèles + intégration)
bin/rails test:system       # tests système (Chrome headless)
```

## Qualité

```bash
bin/rubocop        # lint (rubocop-rails-omakase) ; -A pour autocorriger
bin/brakeman        # scan de sécurité
```

Le CI (`.github/workflows/ci.yml`) exécute brakeman, rubocop, puis
`db:test:prepare test test:system`.
