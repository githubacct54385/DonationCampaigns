class AddStripeAcctNumberToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :StripeAcctNumber, :string
  end
end
