class AddRakutenSellerIdToSellers < ActiveRecord::Migration[5.2]
  def change
    add_column :sellers, :rakuten_seller_id, :string
  end
end
