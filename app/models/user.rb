class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :products, primary_key: :email, foreign_key: :user
  has_many :product_stocks, primary_key: :email, foreign_key: :user
  has_many :product_tracks
  has_many :materials, primary_key: :email, foreign_key: :user
  has_many :material_stocks, primary_key: :email, foreign_key: :user
  has_many :recipes, primary_key: :email, foreign_key: :user
  has_many :categories, primary_key: :email, foreign_key: :user
  has_many :locations, primary_key: :email, foreign_key: :user
  has_many :sellers, primary_key: :email, foreign_key: :user
  has_many :suppliers, primary_key: :email, foreign_key: :user
  has_many :reports, primary_key: :email, foreign_key: :user

end
