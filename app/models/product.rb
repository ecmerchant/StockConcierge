class Product < ApplicationRecord
  belongs_to :seller, primary_key: 'seller_id', optional: true

  require 'typhoeus'
  require 'nokogiri'
  require 'open-uri'
  require 'net/http'

  def get_stock
    if rakuten_item_code.blank? then
      logger.debug("------------ get rakuten_item_ccode -------------")
      if rakuten_url.present? then
        url = rakuten_url
=begin
        request = Typhoeus::Request.new(
          url,
          method: :get
        )

        request.run
        response = request.response
        response_body = response.body
=end
        ua ="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36"
        # response_body = URI.open(url, 'User-Agent' => ua, redirect: :true).read

        response = Net::HTTP.get_response(URI.parse(url))

        logger.debug(url)
        logger.debug(response.code)
        logger.debug(response.body)

        response_body = response.body

        rakuten_item_code = response_body.match(/item_code=([\s\S]*?)&/)[1]       
        logger.debug(rakuten_item_code)

        self.update(
          rakuten_item_code: rakuten_item_code
        )
      else
        logger.debug("------------ rakuten_url empty -------------")
      end
    end

    rakuten_app_id = ENV['RAKUTEN_APP_ID']
    url = "https://app.rakuten.co.jp/services/api/IchibaItem/Search/20170706?format=json&itemCode=" + rakuten_item_code.to_s + "&page=" + (page + 1).to_s + "&applicationId=" + rakuten_app_id.to_s

    request = Typhoeus::Request.new(
      url,
      method: :get
    )

    request.run
    response = request.response
    response_body = response.body

    doc = JSON.parse(response_body)

    list_items = doc.dig('Items')

    if list_items.blank? then
      return
    end

    list_item = list_items.first.dig('Item')

    price = list_item.dig('itemPrice')
    availability = list_item.dig('availability')
    review_count = list_item.dig('reviewCount')
    review_average = list_item.dig('reviewAverage')

    logger.debug("------------- item info -------------")
    logger.debug(rakuten_item_code)
    logger.debug(price)
    logger.debug(availability)
    logger.debug(review_count)    
    logger.debug(review_average)

  end

end