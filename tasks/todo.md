# Phase 5: Budget vs. Actual Graph

## Tasks

- [x] Plan approved
- [x] Write spec: spec/queries/weekly_spend_query_spec.rb
- [x] Create query object: app/queries/weekly_spend_query.rb
- [x] Pin chartkick + Chart.js in config/importmap.rb and application.js
- [x] Load @weekly_spend in ExpensesController#index
- [x] Add chart to app/views/expenses/index.html.erb
- [x] Run full RSpec suite — 136 examples, 0 failures

## Review

Phase 5 complete. All 136 RSpec examples pass (up from 131 in Phase 4).

### Delivered
- WeeklySpendQuery object (app/queries/weekly_spend_query.rb) using groupdate's group_by_week
- 8-week bar chart with dashed $175/week target line overlay on Groceries envelope detail page
- TDD: spec written first, query built to make it pass
- Chartkick + Chart.js wired via importmap (CDN pin for Chart.js)

### PostgreSQL + groupdate timezone bug
- groupdate casts date columns to timestamptz before applying timezone (America/New_York)
- 2026-03-22 00:00 UTC → 2026-03-21 20:00 EDT (Saturday) → bucketed to previous week
- Fix: time_zone: false on group_by_week to skip timezone conversion for date-only columns
