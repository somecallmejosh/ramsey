# Records the debt's balance just before a payment was logged, so removing
# that payment can put the balance back exactly. Older rows stay NULL and
# fall back to the previous payment's balance_after (or the debt's original
# balance) — see DebtPayment#balance_if_removed.
class AddBalanceBeforeToDebtPayments < ActiveRecord::Migration[8.1]
  def change
    add_column :debt_payments, :balance_before, :decimal, precision: 10, scale: 2
  end
end
