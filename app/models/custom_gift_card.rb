class ValuesValidator < ActiveModel::Validator
    def validate(record)
        values = record.values
        first = record.values.first.try(:to_i)

        last = record.values.last.try(:to_i)

				last_index = values.length - 1

			if values.blank?
				record.errors.add :base, "values can't be empty"
			end
      if first != record.min_range
        record.errors.add :base, "first value in values field is not equal to Min Range"
      end

      if last != record.max_range
        record.errors.add :base, "last value in values field is not equal Max Range"
      end


      values.each_with_index do |value, index|
				if  index > 0 && index < last_index
					if value <= first
					record.errors.add :base, "#{value} at postion #{index + 1} has to be greater than Min Range value"
					end
					if value >= last
						record.errors.add :base, "#{value} at postion #{index + 1} has to be less than Max Range"
					end
				end
      end

    end
  end
class CustomGiftCard < ApplicationRecord
    mount_uploader :logo, CustomGiftCardLogoUploader


    belongs_to :business
    belongs_to :profile

    validates_presence_of :logo, :values, :caption, :color, :desc, :disclosures, :discount, :fontcolor, :max_range, :min_range, on: :create
    validates :caption, length: { minimun: 3, maximum: 50 }
    validates :desc, length: { minimun: 3, maximum: 500 }
    validates :disclosures, length: { maximum: 100 }, allow_blank: true
    validates :discount, numericality: { only_integer: false }
    validates :min_range, numericality: { only_integer: true, greater_than_or_equal_to: 500,  less_than_or_equal_to: 99999}
    validates :max_range, numericality: { only_integer: true, less_than_or_equal_to: 100000, greater_than_or_equal_to: 501}
		validate :min_range_is_less_than_max_range?


    validates_with ValuesValidator

		private

		def min_range_is_less_than_max_range?
			if min_range.try(:to_i) >= max_range.try(:to_i)
				errors.add(:min_range, 'cannot be greater than or equal to Max Range')
			end
		end

end
