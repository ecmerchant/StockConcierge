class CreateMaterials < ActiveRecord::Migration[5.2]
  def change
    create_table :materials do |t|
      t.string :user
      t.string :material_id
      t.text :name
      t.string :category_id
      t.decimal :cost, precision: 9, scale: 2
      t.decimal :expense, precision: 9, scale: 2
      t.string :supplier_id
      t.string :location_id
      t.integer :qty_per_package
      t.integer :package_per_case
      t.timestamps
    end
  end
end
