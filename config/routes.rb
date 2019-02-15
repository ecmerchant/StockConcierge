
require 'resque/server'

Rails.application.routes.draw do

  get 'reports/edit'
  get 'reports/edit/:product_id', to: 'reports#edit'
  post 'reports/edit'
  post 'reports/clear'
  get 'reports/output'

  get 'categories/edit'
  post 'categories/edit'
  get 'categories/template'
  get 'categories/output'
  post 'categories/delete'

  get 'product_stocks/edit'
  get 'product_stocks/edit/:product_id', to: 'product_stocks#edit'
  post 'product_stocks/edit'
  get 'product_stocks/template'
  get 'product_stocks/output'
  post 'product_stocks/delete'
  post 'product_stocks/regist'

  get 'suppliers/edit'
  post 'suppliers/edit'
  get 'suppliers/template'
  get 'suppliers/output'
  post 'suppliers/delete'

  get 'materials/edit'
  get 'materials/edit/:material_id', to: 'materials#edit'
  post 'materials/edit'
  get 'materials/template'
  get 'materials/output'
  post 'materials/delete'

  get 'material_stocks/edit'
  get 'material_stocks/edit/:material_id', to: 'material_stocks#edit'
  post 'material_stocks/edit'
  get 'material_stocks/template'
  get 'material_stocks/inventory'
  get 'material_stocks/delete/:id', to: 'material_stocks#delete'

  get 'recipes/edit'
  post 'recipes/edit'
  get 'recipes/edit/:product_id', to: 'recipes#edit'
  get 'recipes/template'
  get 'recipes/output'
  post 'recipes/delete'

  get 'sellers/edit'
  post 'sellers/edit'
  get 'sellers/template'
  get 'sellers/output'
  post 'sellers/delete'

  get 'products/show'
  get 'products/check'
  post 'products/check'
  get 'products/check_output'
  post 'products/check_output'
  get 'products/check_template'
  get 'products/pickup'
  post 'products/clear'

  get 'products/template'
  get 'products/output'
  get 'products/edit'
  post 'products/edit'
  post 'products/delete'

  get 'products/destroy'
  post 'products/destroy'

  root to: 'products#show'

  mount Resque::Server.new, at: "/resque"

  devise_scope :user do
    get '/users/sign_out' => 'devise/sessions#destroy'
    get '/sign_in' => 'devise/sessions#new'
  end

  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'

  devise_for :users, :controllers => {
   :registrations => 'users/registrations'
  }

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
