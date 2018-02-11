class AddPictureToCampaigns < ActiveRecord::Migration[5.1]
  def change
    add_column :campaigns, :picture, :string
  end
end
