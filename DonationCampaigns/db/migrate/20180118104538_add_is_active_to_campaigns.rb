class AddIsActiveToCampaigns < ActiveRecord::Migration[5.1]
  def change
    add_column :campaigns, :IsActive, :boolean
  end
end
