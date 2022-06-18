class CreateProductTracks < ActiveRecord::Migration[5.2]
  def change
    create_table :product_tracks do |t|
      t.string :rakuten_item_code
      t.integer :price
      t.string :availability
      t.integer :review_count
      t.float :review_average

      t.timestamps
    end
    add_index :product_tracks, :rakuten_item_code
  end
end
