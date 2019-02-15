class CreateProductStocks < ActiveRecord::Migration[5.2]
  def change
    create_table :product_stocks do |t|
      t.string :user
      t.string :product_id
      t.string :action
      t.integer :input_qty
      t.integer :self_qty
      t.integer :fba_qty
      t.integer :total_qty
      t.integer :arriving_qty

      t.timestamps
    end
  end
end
