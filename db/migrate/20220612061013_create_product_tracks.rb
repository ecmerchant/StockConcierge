class CreateProductTracks < ActiveRecord::Migration[5.2]
  def change
    create_table :product_tracks do |t|
      t.references :product, foreign_key: true
      t.integer :price
      t.string :availability
      t.integer :review_count
      t.float :review_average

      t.timestamps
    end
  end
end
