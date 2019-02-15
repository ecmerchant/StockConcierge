class CreateRecipes < ActiveRecord::Migration[5.2]
  def change
    create_table :recipes do |t|
      t.string :user
      t.string :product_id
      t.string :material_id
      t.integer :required_qty

      t.timestamps
    end
  end
end
