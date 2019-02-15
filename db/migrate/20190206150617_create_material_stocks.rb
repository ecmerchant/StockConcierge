class CreateMaterialStocks < ActiveRecord::Migration[5.2]
  def change
    create_table :material_stocks do |t|
      t.string :user
      t.string :material_id
      t.string :action
      t.integer :input_case
      t.integer :input_package
      t.integer :input_qty
      t.integer :current_case
      t.integer :current_package
      t.integer :current_qty
      t.integer :current_total
      t.integer :arriving_case
      t.integer :arriving_package
      t.integer :arriving_qty
      t.integer :arriving_total
      t.integer :shipping_case
      t.integer :shipping_package
      t.integer :shipping_qty
      t.integer :shipping_total
      t.date :expire
      t.timestamps
    end
  end
end
