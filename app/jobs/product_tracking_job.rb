class ProductTrackingJob < ApplicationJob

  queue_as :default

  rescue_from(StandardError) do |exception|
    # Do something with the exception
    logger.debug("Standard Error Escape Active Job")
    logger.error exception
  end

  def perform
    users = User.all
    users.each do |user|
      user_id = user.id
      Product.check_stock(user_id)
    end
  end

end
