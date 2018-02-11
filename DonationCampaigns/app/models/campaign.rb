class Campaign < ApplicationRecord
	belongs_to :user
	validates :name,  presence: true, length: { maximum: 50 }, uniqueness: { case_sensitive: false }
	validates :description, presence: true, length: { maximum: 255 }
	validates :goal, presence: true, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 10000 }
	validates :picture, presence: true
	mount_uploader :picture, ImageUploader
	validate  :picture_size

	private
  		# Validates the size of an uploaded picture.
    	def picture_size
      		if picture.size > 5.megabytes
        		errors.add(:picture, "should be less than 5MB")
      		end
    	end
end
