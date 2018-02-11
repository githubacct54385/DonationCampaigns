class Charge < ApplicationRecord
	validates :amount,  presence: true
end
