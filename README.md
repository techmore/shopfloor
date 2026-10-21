# Shopfloor

Shopfloor is a Rails 8.1 manufacturing-operations platform: ISO 9001 document
control with a review/approval workflow, production scheduling (work stations,
shifts, work orders, assignments, daily goals), weigh stations with NFC-tagged
traceability, and parts/inventory management.

The repository contains two things:

| Layer | Where | Status |
| --- | --- | --- |
| Rails application | `app/`, `config/`, `db/`, `spec/` | Models, schema, Devise auth, Pundit base policy, home/dashboard/sign-in views, RSpec suite |
| Bootstrap generators | `scripts/`, `scripts/bootstrap/*.sh` | Shell scripts that stand up an Ubuntu VM and generate the full set of controllers, views and policies for each module (documents, scheduling, weigh/inventory, admin) |

The module controllers referenced by `config/routes.rb` (documents, schedule,
weigh stations, parts, warehouse, admin, ...) are produced by the bootstrap
scripts and are **not** part of the committed application yet.

## Requirements

- Ruby 3.4.1 (see `.ruby-version`)
- PostgreSQL 14+ (the app, cache, queue and cable stores are all Postgres)
- `libpq-dev`, `libyaml-dev` and a C toolchain for native gems

## Setup

```sh
bundle install
bin/rails db:prepare      # creates the database, loads db/schema.rb, runs db/seeds.rb
bin/dev                   # Puma + Tailwind watcher (see Procfile.dev)
```

`bin/setup` does the same and also clears logs and temp files.

By default `config/database.yml` connects over the local socket as your OS user.
To point at another server set `DATABASE_URL`, for example
`DATABASE_URL=postgres://shopfloor:shopfloor@localhost:5432/shopfloor_development`.

### Demo accounts

`db/seeds.rb` creates one user per role, all with the password `password123`:

| Role | Email |
| --- | --- |
| admin | admin@shopfloor.local |
| scheduler | scheduler@shopfloor.local |
| author | author@shopfloor.local |
| reviewer | reviewer@shopfloor.local |
| approver | approver@shopfloor.local |
| operator | operator@shopfloor.local |
| viewer | viewer@shopfloor.local |

Roles are ordered viewer < operator < author < reviewer < approver < scheduler <
admin; `User#role_at_least?(:reviewer)` compares against that order.

## Running the tests

```sh
RAILS_ENV=test bin/rails db:schema:load   # first time only
bundle exec rspec
```

The suite (RSpec + FactoryBot + shoulda-matchers) covers every model, lints every
factory and trait, and checks that `db/seeds.rb` produces users with the expected
roles. `DATABASE_URL` works here too; the test database defaults to
`shopfloor_test`.

Static checks, as run in CI:

```sh
bin/rubocop                 # style (rubocop-rails-omakase)
bin/brakeman --no-pager     # Rails security scan
bin/bundler-audit           # known gem advisories
bin/importmap audit         # known JS advisories
```

`bin/ci` runs all of the above plus the specs in one go.

## Continuous integration

`.github/workflows/ci.yml` runs on pushes to `main` and on pull requests:
`scan_ruby` (Brakeman + bundler-audit), `scan_js` (importmap audit), `lint`
(RuboCop) and `test` (RSpec against a Postgres 16 service container).

## Deployment

- `config/deploy.yml` + `.kamal/` – Kamal/Docker deployment (`Dockerfile`,
  Thruster, Solid Queue/Cache/Cable on Postgres).
- `scripts/vm-bootstrap.sh`, `scripts/bootstrap.sh`, `scripts/provision-*.sh`
  – Multipass/Incus VM provisioning and the phase-by-phase app generator.
- `deploy.html` / `design.html` – the original deployment and design notes.

Secrets come from `config/credentials.yml.enc` (needs `config/master.key`,
never committed) and environment variables such as `SHOPFLOOR_DATABASE_PASSWORD`.

## Screenshots

_Coming soon: landing page, sign-in, dashboard, getting-started guide._
