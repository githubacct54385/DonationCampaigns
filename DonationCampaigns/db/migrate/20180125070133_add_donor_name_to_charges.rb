class AddDonorNameToCharges < ActiveRecord::Migration[5.1]
  def change
    add_column :charges, :DonorName, :string
  end
end
