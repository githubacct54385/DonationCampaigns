class CreateCampaigns < ActiveRecord::Migration[5.1]
  def change
    create_table :campaigns do |t|
      t.string :name
      t.string :description
      t.integer :goal
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end
