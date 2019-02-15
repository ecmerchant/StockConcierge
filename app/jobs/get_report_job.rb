class GetReportJob < ApplicationJob
  queue_as :get_report

  rescue_from(StandardError) do |exception|
    # Do something with the exception
    logger.debug("Standard Error Escape Active Job")
    logger.error exception
  end

  def perform(user)
    ProductStock.get_report(user)
  end
end
