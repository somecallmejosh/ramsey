# Idempotent seeds — safe to run multiple times.

# ── Users ──────────────────────────────────────────────────────────────────────
josh = User.find_or_create_by!(email_address: "josh@thebrileys.com") do |u|
  u.password              = "changeme123!"
  u.password_confirmation = "changeme123!"
  u.role                  = :admin
end

sally = User.find_or_create_by!(email_address: "sally@thebrileys.com") do |u|
  u.password              = "changeme123!"
  u.password_confirmation = "changeme123!"
  u.role                  = :standard
end

puts "Users: Josh (admin) and Sally (standard) ready."

# ── Envelopes ─────────────────────────────────────────────────────────────────
envelope_data = [
  { name: "Groceries",         position: 1,  budget: 700.00 },
  { name: "Restaurants",       position: 2,  budget: 150.00 },
  { name: "Work meals",        position: 3,  budget: 100.00 },
  { name: "Gas",               position: 4,  budget: 300.00 },
  { name: "Clothing",          position: 5,  budget:  75.00 },
  { name: "Entertainment",     position: 6,  budget:  75.00 },
  { name: "Blow money — Josh", position: 7,  budget:  50.00 },
  { name: "Blow money — Sally", position: 8,  budget:  50.00 },
  { name: "Hygiene",           position: 9,  budget:  50.00 }
]

year  = Date.current.year
month = Date.current.month

envelope_data.each do |attrs|
  envelope = Envelope.find_or_create_by!(name: attrs[:name]) do |e|
    e.position = attrs[:position]
    e.active   = true
  end

  EnvelopeBudget.find_or_create_by!(
    envelope: envelope,
    year:     year,
    month:    month
  ) do |eb|
    eb.amount = attrs[:budget]
  end
end

puts "Envelopes: #{Envelope.count} envelopes with #{Date::MONTHNAMES[month]} #{year} budgets ready."
puts ""
puts "─────────────────────────────────────────"
puts " Josh:  josh@thebrileys.com / changeme123!"
puts " Sally: sally@thebrileys.com / changeme123!"
puts " ⚠️  Change passwords before going live."
puts "─────────────────────────────────────────"
