class CreateReports < ActiveRecord::Migration[5.2]
  def change
    create_table :reports do |t|
      t.string :user
      t.string :product_id
      t.decimal :impression
      t.decimal :click
      t.decimal :click_through_rate
      t.decimal :click_per_cost
      t.decimal :cost
      t.decimal :total_sale
      t.decimal :adv_cost_of_sale
      t.decimal :return_on_adv_spend
      t.decimal :session
      t.decimal :session_rate
      t.decimal :page_view
      t.decimal :page_view_rate
      t.decimal :cart_box_rate
      t.decimal :order_quantity
      t.decimal :unit_session_rate
      t.decimal :sale
      t.decimal :total
      t.date :recorded_at

      t.timestamps
    end
  end
end
