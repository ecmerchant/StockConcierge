class AddSalableDaysToProducts < ActiveRecord::Migration[5.2]
  def change
    add_column :products, :salable_days, :integer, default: 0
  end
end
