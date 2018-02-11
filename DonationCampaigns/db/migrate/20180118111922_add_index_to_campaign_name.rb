class AddIndexToCampaignName < ActiveRecord::Migration[5.1]
  def change
  	add_index :campaigns, :name, unique: true
  end
end
