class AddRakutenInfoToProducts < ActiveRecord::Migration[5.2]
  def change
    add_column :products, :rakuten_url, :string
    add_column :products, :rakuten_item_code, :string
  end
end
