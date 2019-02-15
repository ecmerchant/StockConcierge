class AddAdminFlgToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :admin_flg, :boolean, default: false, null: false
  end
end
