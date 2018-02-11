class CreateCharges < ActiveRecord::Migration[5.1]
  def change
    create_table :charges do |t|
      t.string :charge_id
      t.integer :amount
      t.integer :campaign_id
      t.string :name

      t.timestamps
    end
  end
end
