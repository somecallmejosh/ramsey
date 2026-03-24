# Phase 4: Shopping List Enhancements

## Tasks

- [x] Plan approved
- [x] Add :create and :destroy to shopping_items routes
- [x] Expand ShoppingItemsController with create/destroy actions
- [x] Add STORES constant to ShoppingItem model
- [x] Extract shopping list partial with store grouping + delete buttons
- [x] Create shopping_items/_form.html.erb (add item form)
- [x] Create create.turbo_stream.erb and destroy.turbo_stream.erb
- [x] Write system spec: spec/system/shopping_list_spec.rb
- [x] Run full RSpec suite — 131 examples, 0 failures

## Review

Phase 4 complete. All 131 RSpec examples pass (up from 127 in Phase 3).

### Delivered
- Store grouping with section headers in the confirmed shopping list view
- Add item form (name, quantity, store dropdown, estimated cost) with inline validation errors via Turbo Stream
- Delete item via Turbo Stream (row removed without page reload)
- Turbo Stream create: success replaces #shopping-list, error replaces #add-shopping-item-form

### Chrome 146 headless notes
- click_button unreliable for form submission when no prior field interaction
- Fixed in spec via page.execute_script requestSubmit()
- Consistent with send_keys(:return) pattern used in log_expense_spec
