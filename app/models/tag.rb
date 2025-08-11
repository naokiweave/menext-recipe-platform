class Tag < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  
  has_many :recipe_tags, dependent: :destroy
  has_many :recipes, through: :recipe_tags
end