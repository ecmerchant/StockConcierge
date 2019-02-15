class Recipe < ApplicationRecord
  belongs_to :product, primary_key: 'product_id', optional: true
  belongs_to :material, primary_key: 'material_id', optional: true
end
