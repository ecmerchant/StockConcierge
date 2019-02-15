class Material < ApplicationRecord
  has_many :material_stocks
  belongs_to :location, primary_key: 'location_id', optional: true
  belongs_to :category, primary_key: 'category_id', optional: true
  belongs_to :supplier, primary_key: 'supplier_id', optional: true
end
