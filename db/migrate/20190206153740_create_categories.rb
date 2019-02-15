class CreateCategories < ActiveRecord::Migration[5.2]
  def change
    create_table :categories do |t|
      t.string :user
      t.string :category_id
      t.text :name

      t.timestamps
    end
  end
end
