# Phase 6: Work Lunch Tracker

## Tasks

- [x] Plan approved
- [x] Write spec first: spec/models/lunch_log_spec.rb
- [x] Generate migration + create app/models/lunch_log.rb — make spec pass
- [x] Add routes: resources :lunch_logs, only: [:index, :create, :destroy]
- [x] Create app/controllers/lunch_logs_controller.rb (user-scoped)
- [x] Create app/helpers/lunch_logs_helper.rb (weeks_for_month)
- [x] Create views: index, _day_cell, _stats, create.turbo_stream, destroy.turbo_stream
- [x] Add Lunch nav item to app/components/nav_component.html.erb
- [x] Create spec/factories/lunch_logs.rb
- [x] Create spec/requests/lunch_logs_spec.rb (user-scoping)
- [x] Run full RSpec suite — 152 examples, 0 failures

## Review

Phase 6 complete. All 152 RSpec examples pass (up from 136 in Phase 5).

### Delivered
- LunchLog model with user_id + logged_on (date), unique per user-day, SAVINGS_PER_LUNCH = 8
- Mon–Fri weekly grid with one-tap Log/Packed toggle per day via Turbo Stream
- Monthly stats card: days packed + estimated savings ($8 × days)
- Work Meals envelope remaining balance displayed alongside savings
- Month selector (6 months back) matching expenses page pattern
- User-scoping enforced: current_user.lunch_logs.find() → 404 on other user's record
- "Lunch" nav item added to bottom nav (check icon)
