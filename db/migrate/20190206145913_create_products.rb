class CreateProducts < ActiveRecord::Migration[5.2]
  def change
    create_table :products do |t|
      t.string :user
      t.string :product_id
      t.text :name
      t.decimal :price
      t.decimal :fee
      t.decimal :expense
      t.decimal :cost
      t.decimal :profit
      t.string :seller_id
      t.string :fba_sku
      t.string :self_sku
      t.timestamps
    end
  end
end
