# PayWithRuby

JSON RESTful API for a small ride-hailing service (Ruby + Sinatra + Sequel + PostgreSQL). Payments via Wompi API (sandbox-first).

See `AGENTS.md` for agent rules and `../assistant/` for project knowledge.

## Quick start

```bash
bundle install
cp .env.example .env
docker compose up -d db
sequel -m db/migrations "$DATABASE_URL"
rackup -p 4567
curl localhost:4567/api/v1/health
bundle exec rspec
```
