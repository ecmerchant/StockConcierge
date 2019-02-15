class AddRecordedAtToProductStocks < ActiveRecord::Migration[5.2]
  def change
    add_column :product_stocks, :recorded_at, :date
  end
end
