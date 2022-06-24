class Product < ApplicationRecord
  belongs_to :seller, primary_key: 'seller_id', optional: true
  has_many :product_tracks, primary_key: :rakuten_item_code, foreign_key: :rakuten_item_code, dependent: :destroy
  has_many :reports, primary_key: :product_id, foreign_key: :product_id
  has_many :recipes, primary_key: :product_id, foreign_key: :product_id
  has_many :product_stocks, primary_key: :product_id, foreign_key: :product_id, dependent: :destroy
  has_one :latest_stock, -> {latest_stock}, primary_key: :product_id, foreign_key: :product_id, dependent: :destroy, class_name: 'ProductStock'

  require 'typhoeus'
  require 'nokogiri'
  require 'open-uri'
  require 'net/http'

  def calc_salable_days
    data = product_tracks.order(created_at: :asc).pluck(:created_at, :availability)
    s = 0
    if data.length > 1 then
      (0..(data.length - 2)).each do |index|
        data_1 = data[index]
        data_2 = data[index + 1]
        h1 = data_1[1].to_i
        t1 = data_1[0].to_i
        h2 = data_2[1].to_i
        t2 = data_2[0].to_i
        delta_t = ((t2 - t1) / 3600).floor
        delta_s = (h1 * delta_t) + (h2 - h1) * delta_t / 2 
        s = s + delta_s
      end
    end
    return (s / 24).round(1)
  end

  def self.check_stock(user_id)
    user = User.find(user_id)
    sellers = user.sellers
    products = user.products

    rakuten_urls = products.pluck(:rakuten_url)
    rakuten_item_codes = products.pluck(:rakuten_item_code)
    rakuten_urls_without_item_code = products.where(rakuten_item_code: [nil, ""]).pluck(:rakuten_url)

    sellers.each do |seller|
      rakuten_seller_id = seller.rakuten_seller_id
      if rakuten_seller_id.present? then

        logger.debug(rakuten_seller_id)
        
        rakuten_app_id = ENV['RAKUTEN_APP_ID']
        rakuten_hash = {}
        counter = 1
        check_hash = {}

        (1..100).each do |page|

          url = "https://app.rakuten.co.jp/services/api/IchibaItem/Search/20170706?format=json&shopCode=" + rakuten_seller_id.to_s + "&availability=0&page=" + page.to_s + "&applicationId=" + rakuten_app_id.to_s

          request = Typhoeus::Request.new(
            url,
            method: :get
          )
  
          request.run
          response = request.response
          response_body = response.body
  
          doc = JSON.parse(response_body)
  
          # logger.debug(JSON.pretty_generate(doc))
  
          page_count = doc.dig('pageCount').to_i
          list_items = doc.dig('Items')
  
          list_items.each do |list_item|
            list_item = list_item.dig('Item')
  
            rakuten_item_code = list_item.dig('itemCode')
            rakuten_url = list_item.dig('itemUrl')
            price = list_item.dig('itemPrice')
            availability = list_item.dig('availability')
            review_count = list_item.dig('reviewCount')
            review_average = list_item.dig('reviewAverage')
            
            logger.debug("------------- item info -------------")
            logger.debug("No. " + counter.to_s)
            logger.debug(rakuten_url)
            logger.debug(rakuten_item_code)
            logger.debug(price)
            logger.debug(availability)
            logger.debug(review_count)    
            logger.debug(review_average)

            counter += 1

            rakuten_hash[rakuten_url] = rakuten_item_code

            logger.debug("check 1")

            if rakuten_url.end_with?("/") then
              rakuten_url2 = rakuten_url.chop
            end

            if rakuten_urls_without_item_code.present? then
              logger.debug("check 2")
              if rakuten_urls_without_item_code.include?(rakuten_url) || rakuten_urls_without_item_code.include?(rakuten_url2) then
                logger.debug("check 3")
                if rakuten_urls_without_item_code.include?(rakuten_url) then
                  product = products.find_by(rakuten_url: rakuten_url)
                elsif rakuten_urls_without_item_code.include?(rakuten_url2) then
                  product = products.find_by(rakuten_url: rakuten_url2)
                end
                #product = products.find_by(rakuten_url: rakuten_url)
                product.update(
                  rakuten_item_code: rakuten_item_code
                )
                rakuten_item_codes.push(rakuten_item_code)
              end
            end

            if rakuten_item_codes.include?(rakuten_item_code) then
              logger.debug("check 4")
              if check_hash.has_key?(rakuten_item_code) == false then
                logger.debug("check 5")
                ProductTrack.create(
                  rakuten_item_code: rakuten_item_code,
                  availability: availability,
                  price: price,
                  review_count: review_count,
                  review_average: review_average
                )
                check_hash[rakuten_item_code] = rakuten_item_code
              end
            end
            logger.debug("check 6")
          end

          if page >= page_count then
            break
          end 
          sleep(1)
        end
      end
    end
    
  end

  def get_stock
    if rakuten_item_code.blank? then
      logger.debug("------------ get rakuten_item_code -------------")
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