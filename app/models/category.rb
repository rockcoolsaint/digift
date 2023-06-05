class Category < ApplicationRecord
  belongs_to :admin
  has_many :category_items

  validates_presence_of :title, on: :create
  validates_presence_of :title, on: :update
  validates :title, uniqueness: true
end
