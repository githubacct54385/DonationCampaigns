class AddMoneyRaisedToCampaigns < ActiveRecord::Migration[5.1]
  def change
    add_column :campaigns, :MoneyRaised, :integer
  end
end
