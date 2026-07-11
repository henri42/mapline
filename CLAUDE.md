# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Mapline lets history enthusiasts build historical/geopolitical maps that evolve over time, paired with a navigable timeline: the reader drags a cursor across key dates and the map animates. Greenfield Rails 8 app.

**`PLAN.md` is the source of truth** for scope, architecture decisions, and the milestone breakdown (M0–M7). Read it before starting non-trivial work. `IDEE.md` is the original French brief. Milestones M0–M3 are implemented; M4+ (drawing, geometry versioning, animation, events) are not yet built.

UI copy, code comments, and test names are written in **French**. Match that.

## Commands

```bash
bin/dev                                   # Rails + Vite dev servers (Procfile.dev via Foreman)
bin/rails test                            # full Minitest suite (models + integration)
bin/rails test test/models/mapline_test.rb          # one file
bin/rails test test/models/mapline_test.rb:14       # one test by line
bin/rails test -n "/publication/"                   # tests matching a pattern
bin/rails test:system                     # system tests (headless Chrome; CI runs these)
bin/rubocop            # lint (rubocop-rails-omakase); -A to autocorrect
bin/brakeman           # security scan (runs in CI)
bin/rails db:migrate   # apply migrations (also updates db/schema.rb)
npx vite build         # verify the JS/CSS bundle compiles (no browser needed)
npm add <pkg>          # add a JS dependency (npm + package-lock.json)
```

CI (`.github/workflows/ci.yml`) runs brakeman, rubocop, and `db:test:prepare test test:system`.

## Architecture

**Stack:** Rails 8.0 / Ruby 4.0, maximal Rails-8 defaults — SQLite (dev/test/prod), Solid Queue/Cache/Cable, Propshaft, the built-in authentication generator. Server views are **Phlex** (`phlex-rails`); client JS is **Stimulus + Turbo bundled by `vite_rails`** (not importmaps/Sprockets). Styling is **Tailwind CSS v4** via `@tailwindcss/vite`.

**The app module is `MaplineApp`, not `Mapline`** (`config/application.rb`). This is deliberate: the domain's central model is `Mapline`, and a same-named app module would shadow the model constant under Zeitwerk. Don't "fix" it back.

### Phlex views + the component Kit

- Views live in `app/views/**` under the `Views::` namespace; components in `app/components/**` under `Components::` (both autoloaded via `config/initializers/phlex.rb`). A view class is e.g. `Views::Maplines::Edit`; a controller renders it with `render Views::Maplines::Edit.new(...)`.
- Every full page renders inside the shared chrome via `render Views::Layout.new(title:) do ... end`.
- `Components` is a **Phlex::Kit**, and `Components::Base` does `include Components`, so inside any view/component you call components by capitalized name without `render`: `Button(...)`, `Link(...)`, `StatusBadge(...)`.
  - `Components::Button` wraps `button_to` (a form action); `Components::Link` wraps `link_to`. Both take `variant:` (`:primary` / `:ghost` / `:danger`). Variant→CSS lives in `Components::Base#button_classes`, reused by `form.submit` calls (`class: button_classes(:primary)`). Add button/link styles there, not ad-hoc `btn` classes in views.
- `<turbo-frame>` is registered as a Phlex custom element in `Components::Base` (`register_element :turbo_frame`), so write `turbo_frame(id: "...") { ... }`.

### Frontend wiring

- Entry: `app/frontend/entrypoints/application.js` starts Stimulus and **auto-registers every `app/frontend/controllers/**/*_controller.js`** via `stimulus-vite-helpers` (filename → identifier, e.g. `map_controller.js` → `map`). Just add the file; no manual registration.
- Tailwind config is CSS-first in `app/frontend/styles/application.css`: design tokens under `@theme` become utilities (`bg-canvas`, `text-muted`…), reusable `.btn`/`.field` classes under `@layer components`. Because Phlex views live outside the Vite root, they're registered as Tailwind sources with `@source "../../views"` / `@source "../../components"` — new view directories under those are covered automatically.
- CSP is currently disabled (`config/initializers/content_security_policy.rb` fully commented), which is why MapLibre can fetch external tiles and use blob workers without allowances.

### Domain model & conventions

- **`Mapline`** — `status` enum `draft`/`unlisted`/`public` declared with `scopes: false` (a `Mapline.public` scope would clobber `Module#public`); use the `listed`/`accessible_by_link` scopes instead. Publish requirements (≥1 source **and** ≥1 key date) are enforced only in the `:publish` validation context via `publish_as(status)` — not on create. Slugs auto-generate (`parameterize` + random suffix), same pattern as `User`. Access control is `Mapline#viewable_by?(user)`.
- **`Source`** — belongs to a mapline, auto-incrementing `position`. Managed on the editor page through **nested Turbo Frames**: an outer `sources_manager` frame (list + add form; create/delete redirect-refresh it) with per-row `source_<id>` frames for inline edit. Deletes target `sources_manager` via `data-turbo-frame`; the whole flow is redirect-based (no custom turbo_stream rendering).
- **`KeyDate`** — belongs to a mapline; a key date is a "chapter" and the future unit of geometry versioning. Historical dates use a signed **astronomical `year`** (0 = 1 BC) + derived `sort_key` integer (`year * 10_000 + (month||1) * 100 + (day||1)`), not SQL `date` — handles BC years and day/month/year granularity (nullable `month`/`day`). Input is via virtual attributes `year_input` (positive) + `era` (`bc`/`ce`), converted in `before_validation`; use `display_date` for rendering (`label` overrides the auto-format). Validations add French messages to `:base` (no fr locale installed). Same **nested Turbo Frame** CRUD pattern as `Source` (`key_dates_manager` / `key_date_<id>`).
- **Timeline** — `Components::Timeline` (Phlex kit) + `timeline_controller.js` (Stimulus) is the shared editor/reader frise, rendered on both the editor (preview) and public pages. Per-date data rides on the tick elements as `data-*` (no JSON blob). It emits a `timeline:change` event (`{ index, sortKey, keyDateId }`) that the map controllers will consume from M5 onward.
- **Auth** — `Authentication` concern resumes the session on every request (so `Current.user` is available on public pages too) and requires login by default; opt out per-controller with `allow_unauthenticated_access`. Author-scoped controllers load records through `Current.user.maplines` so cross-user access 404s.
- **Maps** — `app/frontend/styles/basemap-neutral.json` is a self-contained MapLibre style over OpenFreeMap vector tiles showing only physical geography (no borders/toponyms/roads). `map_controller.js` renders it read-only on public pages and, in the editor, saves the current center/zoom as the initial view via `PATCH /maplines/:id.json` (`MaplinesController#update` responds to both HTML and JSON).

### Testing notes

- Minitest with fixtures (`test/fixtures/*.yml`), run in parallel. Integration tests sign in by POSTing to `session_url` with the fixture password `"password"`.
- In the test env, `ActiveRecord::RecordNotFound` is **rendered as a 404**, not re-raised — assert `assert_response :not_found`, not `assert_raises`.
- Turbo-frame structure is worth asserting with `assert_select "turbo-frame#..."`; it's the contract that makes the source editor work.
