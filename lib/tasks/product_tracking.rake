namespace :product_tracking do
  desc "商品在庫チェック"
  task :operate => :environment do |task|
    ProductTrackingJob.perform_later
  end
end
