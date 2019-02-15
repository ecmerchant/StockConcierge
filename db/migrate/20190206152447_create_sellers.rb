class CreateSellers < ActiveRecord::Migration[5.2]
  def change
    create_table :sellers do |t|
      t.string :user
      t.string :seller_id
      t.text :name
      t.string :secret_key_id
      t.string :aws_access_key_id
      t.string :mws_auth_token

      t.timestamps
    end
  end
end
