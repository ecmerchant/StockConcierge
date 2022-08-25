class ProductTrack < ApplicationRecord
  belongs_to :product, primary_key: :rakuten_item_code, foreign_key: :rakuten_item_code

end
