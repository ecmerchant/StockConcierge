class CreateSuppliers < ActiveRecord::Migration[5.2]
  def change
    create_table :suppliers do |t|
      t.string :user
      t.string :supplier_id
      t.text :name
      t.string :email
      t.string :phone
      t.string :fax
      t.text :url
      t.text :address
      t.text :memo

      t.timestamps
    end
  end
end
