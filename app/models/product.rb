class Product < ApplicationRecord
  belongs_to :seller, primary_key: 'seller_id', optional: true

end
