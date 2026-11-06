# Development seed data — rich enough to design every screen and state.
#
# Idempotent: each section only runs if its data is missing, so re-running
# never duplicates or clobbers records. To wipe and rebuild from scratch:
#
#   bin/rails db:seed:replant
#
# All dates are relative to Date.current, and randomness is seeded so the
# data set is identical on every fresh run.
#
# Two households:
#   • Briley Household — the "happy path": months of history in every feature.
#   • Sample Household — empty and edge states: no debts or expenses, an
#     unconfirmed AI meal-plan preview, and a failed meal plan.
#
# Push subscriptions are intentionally not seeded: fake endpoints would make
# NotifyAccountMembersJob fail, and leaving them empty keeps the "enable
# notifications" prompt visible for design work. Sessions are created at login.

RNG      = Random.new(42)
TODAY    = Date.current
PASSWORD = "changeme123!"

def money(range) = (RNG.rand(range) * 100).round / 100.0

def weekdays_between(from, to) = (from..to).reject { |d| d.saturday? || d.sunday? }

# ── Accounts & users ──────────────────────────────────────────────────────────
briley = Account.find_or_create_by!(name: "Briley Household")
sample = Account.find_or_create_by!(name: "Sample Household")

def seed_user(email, account, role)
  User.find_or_create_by!(email_address: email) do |u|
    u.account               = account
    u.password              = PASSWORD
    u.password_confirmation = PASSWORD
    u.role                  = role
  end
end

josh   = seed_user("josh@thebrileys.com",  briley, :owner)
sally  = seed_user("sally@thebrileys.com", briley, :member)
taylor = seed_user("taylor@example.com",   sample, :owner)

# ── Envelopes & monthly budgets ───────────────────────────────────────────────
# spend: fraction of budget spent in a full (past) month. >1.0 = over budget.
# now:   fraction spent so far this month, chosen so the current dashboard
#        shows every state: over budget, exactly spent, nearly empty, healthy,
#        and untouched.
BRILEY_ENVELOPES = [
  { name: "Groceries",          budget: 700, spend: 0.92, now: 0.55, per_month: 14, size: 25..85 },
  { name: "Restaurants",        budget: 150, spend: 1.25, now: 1.18, per_month: 5,  size: 18..55 },
  { name: "Work meals",         budget: 100, spend: 0.60, now: 0.30, per_month: 6,  size: 9..16 },
  { name: "Gas",                budget: 300, spend: 0.85, now: 0.93, per_month: 6,  size: 35..60 },
  { name: "Clothing",           budget: 75,  spend: 0.40, now: 0.0,  per_month: 1,  size: 20..60 },
  { name: "Entertainment",      budget: 75,  spend: 0.97, now: 1.0,  per_month: 3,  size: 12..35 },
  { name: "Blow money — Josh",  budget: 50,  spend: 0.70, now: 0.45, per_month: 3,  size: 5..20 },
  { name: "Blow money — Sally", budget: 50,  spend: 0.0,  now: 0.0,  per_month: 0,  size: 5..20 },
  { name: "Hygiene",            budget: 50,  spend: 0.75, now: 0.20, per_month: 2,  size: 8..25 },
  { name: "Christmas",          budget: 0,   spend: 0.0,  now: 0.0,  per_month: 0,  size: 0..0, active: false }
].freeze

NOTES = {
  "Groceries"     => [ "Aldi", "Walmart", "Costco run", "Aldi — weekly", "Farmers market", nil ],
  "Restaurants"   => [ "Chick-fil-A", "Date night", "Pizza Friday", "Chipotle", nil ],
  "Work meals"    => [ "Forgot lunch", "Team lunch", "Coffee", nil ],
  "Gas"           => [ "Shell", "QuikTrip", "Costco gas", nil ],
  "Clothing"      => [ "Kids' shoes", "Target", "Old Navy" ],
  "Entertainment" => [ "Movie tickets", "Netflix", "Bowling", nil ],
  "Hygiene"       => [ "Target", "Walgreens", nil ]
}.freeze

MONTHS_OF_HISTORY = 4 # current month + 3 prior
months = (0...MONTHS_OF_HISTORY).map { |i| TODAY.beginning_of_month << i }

briley_envelopes = BRILEY_ENVELOPES.each_with_index.map do |attrs, i|
  envelope = briley.envelopes.find_or_create_by!(name: attrs[:name]) do |e|
    e.position = i + 1
    e.active   = attrs.fetch(:active, true)
  end

  months.each do |m|
    EnvelopeBudget.find_or_create_by!(envelope: envelope, year: m.year, month: m.month) do |eb|
      eb.amount = attrs[:budget]
    end
  end

  [ envelope, attrs ]
end

# Sample Household: budgets for this month only, no spending (empty states).
[ [ "Groceries", 500 ], [ "Gas", 200 ], [ "Fun money", 60 ] ].each_with_index do |(name, amount), i|
  envelope = sample.envelopes.find_or_create_by!(name: name) { |e| e.position = i + 1 }
  EnvelopeBudget.find_or_create_by!(envelope: envelope, year: TODAY.year, month: TODAY.month) do |eb|
    eb.amount = amount
  end
end

# ── Expenses ──────────────────────────────────────────────────────────────────
if briley.expenses.none?
  users = [ josh, sally ]

  briley_envelopes.each do |envelope, attrs|
    next if attrs[:per_month].zero?

    months.each do |month_start|
      current   = month_start == TODAY.beginning_of_month
      month_end = [ month_start.end_of_month, TODAY ].min
      target    = attrs[:budget] * (current ? attrs[:now] : attrs[:spend])
      next unless target.positive?

      count     = current ? [ (attrs[:per_month] / 2.0).ceil, 1 ].max : attrs[:per_month]

      # Random split of the target into `count` positive amounts.
      weights = Array.new(count) { RNG.rand(0.5..1.5) }
      weights.map { |w| (target * w / weights.sum).round(2) }.each do |amount|
        next unless amount.positive?

        envelope.expenses.create!(
          user:          attrs[:name].include?("Josh") ? josh : users.sample(random: RNG),
          amount:        amount,
          transacted_on: month_start + RNG.rand(0..(month_end - month_start).to_i),
          note:          NOTES.fetch(attrs[:name], [ nil ]).sample(random: RNG)
        )
      end
    end
  end
end

# ── Debts & payments (debt snowball) ──────────────────────────────────────────
# Ordered smallest → largest, as the snowball method prescribes. Payments are
# monthly from `paid_since` months ago; `extra` is snowball money on top of the
# minimum. A debt whose balance hits zero is marked paid off on that date.
if briley.debts.none?
  debts = [
    { name: "Hospital bill",       debt_type: :medical,       original: 1_240,   rate: nil,   minimum: 100,   paid_since: 6, extra: 150 },
    { name: "Discover card",       debt_type: :other,         original: 3_850,   rate: 22.99, minimum: 95,    paid_since: 6, extra: 250 },
    { name: "Furniture loan",      debt_type: :personal_loan, original: 5_400,   rate: 9.5,   minimum: 180,   paid_since: 5, extra: 0 },
    { name: "Honda Odyssey",       debt_type: :vehicle_loan,  original: 24_500,  rate: 6.25,  minimum: 465,   paid_since: 6, extra: 0 },
    { name: "Sally's student loan", debt_type: :student_loan, original: 31_200,  rate: 4.99,  minimum: 330,   paid_since: 6, extra: 0 },
    { name: "Home mortgage",       debt_type: :mortgage,      original: 285_000, rate: 6.875, minimum: 1_872, paid_since: 6, extra: 0 }
  ]

  debts.each_with_index do |d, i|
    # Pretend the debt was partly paid down before tracking began.
    starting = (d[:original] * RNG.rand(0.78..0.95)).round(2)

    debt = briley.debts.create!(
      name: d[:name], debt_type: d[:debt_type], position: i + 1,
      original_balance: d[:original], current_balance: starting,
      interest_rate: d[:rate], minimum_payment: d[:minimum]
    )

    balance = starting
    d[:paid_since].downto(0) do |months_ago|
      paid_on = (TODAY << months_ago).change(day: [ 3 + i, 28 ].min)
      break if paid_on > TODAY || balance.zero?

      interest = d[:rate] ? (balance * d[:rate] / 100 / 12).round(2) : 0
      amount   = [ d[:minimum] + d[:extra] + RNG.rand(0..40), balance + interest ].min.round(2)
      balance  = [ balance + interest - amount, 0 ].max.round(2)

      debt.debt_payments.create!(
        user: [ josh, sally ].sample(random: RNG), amount: amount,
        balance_after: balance, paid_on: paid_on,
        note: (balance.zero? ? "Paid in full! 🎉" : [ nil, "Autopay", "Extra from tax refund" ].sample(random: RNG))
      )
      # The model callback stamps paid_off_at with today; use the real date.
      debt.update_columns(paid_off_at: paid_on) if balance.zero?
    end
  end
end

# ── Lunch logs (packed lunch instead of eating out) ───────────────────────────
if LunchLog.where(user: [ josh, sally ]).none?
  weekdays_between(TODAY.beginning_of_month << 3, TODAY).each do |day|
    LunchLog.create!(user: josh,  logged_on: day) if RNG.rand < 0.75
    LunchLog.create!(user: sally, logged_on: day) if RNG.rand < 0.45
  end
end

# ── Invitations ───────────────────────────────────────────────────────────────
if briley.invitations.none?
  briley.invitations.create!(invited_by: josh, email: "grandma@thebrileys.com",
                             expires_at: 5.days.from_now)
  briley.invitations.create!(invited_by: josh, email: "babysitter@example.com",
                             expires_at: 3.days.ago, created_at: 10.days.ago)
  briley.invitations.create!(invited_by: josh, email: "sally@thebrileys.com",
                             expires_at: 1.month.ago, accepted_at: 5.weeks.ago,
                             created_at: 6.weeks.ago)
end

# ── Meal plans ────────────────────────────────────────────────────────────────
WEEK_MENUS = [
  [ [ "Slow-cooker chicken tacos", "Taco rice bowls" ],
    [ "Spaghetti with meat sauce", "Leftover spaghetti" ],
    [ "Sheet-pan sausage & veggies", "Turkey sandwiches" ],
    [ "Black bean quesadillas", "Sausage & veggie wraps" ],
    [ "Homemade pizza night", "Quesadilla leftovers" ],
    [ "Breakfast for dinner", "Pizza leftovers" ],
    [ "Grilled burgers", "PB&J and fruit" ] ],
  [ [ "Pot roast with potatoes", "Ham & cheese roll-ups" ],
    [ "Beef & broccoli stir fry", "Pot roast sandwiches" ],
    [ "Chicken noodle soup", "Stir fry leftovers" ],
    [ "Baked potato bar", "Chicken soup in a thermos" ],
    [ "Chili and cornbread", "Loaded potato leftovers" ],
    [ "Fish sticks & mac and cheese", "Chili leftovers" ],
    [ "Grilled chicken salads", "Turkey wraps" ] ],
  [ [ "Honey garlic chicken thighs", "Chicken salad croissants" ],
    [ "Taco Tuesday", "Honey garlic chicken & rice" ],
    [ "Lasagna", "Taco salad" ],
    [ "Chicken Caesar wraps", "Lasagna leftovers" ],
    [ "Pancakes & eggs", "Caesar wrap leftovers" ],
    [ "Homemade pizza night", "Bagels & cream cheese" ],
    [ "Pulled pork sandwiches", "Pizza leftovers" ] ]
].freeze

PREP_NOTES = [ "Start slow cooker by 9am", "Double the batch for lunches", "Thaw meat the night before", nil, nil ].freeze

SHOPPING_LIST = [
  [ "Chicken thighs", "3 lb", 8.49, "Aldi" ], [ "Ground beef", "2 lb", 9.98, "Aldi" ],
  [ "Tortillas", "2 packs", 4.38, "Aldi" ], [ "Shredded cheese", "2 bags", 5.58, "Aldi" ],
  [ "Spaghetti", "2 boxes", 1.90, "Aldi" ], [ "Marinara sauce", "2 jars", 3.38, "Aldi" ],
  [ "Russet potatoes", "5 lb", 3.49, "Aldi" ], [ "Bananas", "1 bunch", 1.29, "Aldi" ],
  [ "Eggs", "2 dozen", 5.98, "Costco" ], [ "Milk", "2 gal", 6.58, "Walmart" ],
  [ "Bread", "2 loaves", 3.98, "Walmart" ], [ "Frozen broccoli", "2 bags", 2.98, "Walmart" ],
  [ "Peanut butter", "1 jar", 2.79, "Target" ], [ "Paper towels", "1 pack", 7.99, "Other" ]
].freeze

def week_meals(menu)
  menu.each_with_index.map do |(dinner, lunch), day|
    { "day_of_week" => day, "dinner" => dinner, "lunch" => lunch,
      "prep_note" => PREP_NOTES.sample(random: RNG), "estimated_cost" => money(8.0..22.0) }
  end
end

def week_shopping
  SHOPPING_LIST.map do |name, quantity, cost, store|
    { "name" => name, "quantity" => quantity, "estimated_cost" => cost, "store" => store }
  end
end

# Builds a confirmed plan with persisted meals and shopping items, mirroring
# what MealPlansController#confirm does. `checked` = fraction of list ticked off.
def confirmed_plan(account, user, week_start, menu, checked:)
  meals    = week_meals(menu)
  shopping = week_shopping
  plan = account.meal_plans.create!(
    user: user, week_start: week_start, status: "ready",
    ai_response: { "meals" => meals, "shopping_items" => shopping },
    confirmed_at: week_start.to_time - 1.day
  )
  meals.each { |m| plan.meals.create!(m) }
  shopping.each_with_index do |item, i|
    plan.shopping_items.create!(item.merge("checked" => i < (shopping.size * checked).round))
  end
end

this_week = TODAY.beginning_of_week(:sunday)

if briley.meal_plans.none?
  # Current week is mid-shop; past weeks are fully checked off.
  confirmed_plan(briley, josh,  this_week,          WEEK_MENUS[0], checked: 0.4)
  confirmed_plan(briley, sally, this_week - 7.days, WEEK_MENUS[1], checked: 1.0)
  confirmed_plan(briley, josh,  this_week - 14.days, WEEK_MENUS[2], checked: 1.0)
  confirmed_plan(briley, sally, this_week - 21.days, WEEK_MENUS[0], checked: 1.0)
end

if sample.meal_plans.none?
  # Unconfirmed AI preview → the "Review Your Plan" screen.
  sample.meal_plans.create!(
    user: taylor, week_start: this_week, status: "ready",
    ai_response: { "meals" => week_meals(WEEK_MENUS[2]), "shopping_items" => week_shopping }
  )
  # Failed generation → error state.
  sample.meal_plans.create!(
    user: taylor, week_start: this_week - 7.days, status: "failed",
    error_message: "The meal planner couldn't read the response. Please try again."
  )
end

# ── Summary ───────────────────────────────────────────────────────────────────
puts <<~SUMMARY

  Seeded:
    Accounts       #{Account.count}
    Users          #{User.count}
    Envelopes      #{Envelope.count} (#{EnvelopeBudget.count} monthly budgets)
    Expenses       #{Expense.count}
    Debts          #{Debt.count} (#{DebtPayment.count} payments, #{Debt.paid_off.count} paid off)
    Lunch logs     #{LunchLog.count}
    Invitations    #{Invitation.count}
    Meal plans     #{MealPlan.count} (#{Meal.count} meals, #{ShoppingItem.count} shopping items)

  ─────────────────────────────────────────────────────────────
   Josh    josh@thebrileys.com   / #{PASSWORD}  owner,  full data
   Sally   sally@thebrileys.com  / #{PASSWORD}  member, full data
   Taylor  taylor@example.com    / #{PASSWORD}  owner,  empty/edge states
   ⚠️  Change passwords before going live.
  ─────────────────────────────────────────────────────────────
SUMMARY
