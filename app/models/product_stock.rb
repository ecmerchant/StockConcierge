class ProductStock < ApplicationRecord
  belongs_to :product, primary_key: 'product_id', optional: true

  #FBA在庫数の確認

  scope :recents, -> {order("created_at DESC NULLS LAST")}
  scope :recent, -> {order("created_at DESC NULLS LAST").first}

  def self.get_report(user)
    marketplace_id = "A1VC38T7YXB528"
    sellers = Seller.where(user: user)
    stocks = ProductStock.where(user: user)
    asins = Product.where(user: user).pluck(:product_id)

    sellers.each do |seller|
      logger.debug("-----------------------------")
      logger.debug("======= FBA REPORT ========")
      seller_id = seller.seller_id
      secret_key = seller.secret_key_id
      aws_access_key_id = seller.aws_access_key_id

      report_type = "_GET_AFN_INVENTORY_DATA_"
      client = MWS.reports(
        marketplace: marketplace_id,
        merchant_id: seller_id,
        aws_access_key_id: aws_access_key_id,
        aws_secret_access_key: secret_key
      )

      response = client.request_report(report_type)
      parser = response.parse
      reqid = parser.dig('ReportRequestInfo', 'ReportRequestId')

      mws_options = {
        report_request_id_list: reqid,
      }
      process = ""
      logger.debug(reqid)
      while process != "_DONE_" && process != "_DONE_NO_DATA_"
        response = client.get_report_request_list(mws_options)
        parser = response.parse
        process = parser.dig('ReportRequestInfo', 'ReportProcessingStatus')
        logger.debug(process)
        if process == "_DONE_" then
          genid = parser.dig('ReportRequestInfo', 'GeneratedReportId')
          break
        elsif process == "_DONE_NO_DATA_" then
          genid = "NODATA"
          break
        end
        sleep(5)
      end

      if genid.to_s != "NODATA" then
        response = client.get_report(genid)
        parser = response.parse
        logger.debug("====== report data is ok =======")
        asin_hash = Hash.new
        parser.each do |row|
          if row[4] == 'SELLABLE' then
            tsku = row[0].to_s
            tasin = row[2].to_s
            quantity = row[5].to_i
            if asin_hash.has_key?(tasin) == true then
              temp = asin_hash[tasin]
              quantity = quantity.to_i + temp[2].to_i
              asin_hash[tasin] = [tasin, tsku, quantity]
            else
              asin_hash[tasin] = [tasin, tsku, quantity]
            end

            if asins.include?(tasin) then
              logger.debug("ASIN: " + tasin + " ,FBA stock: " + quantity.to_s)
              target = stocks.find_or_create_by(
                product_id: tasin,
                recorded_at: Date.today
              )
              target.update(
                fba_qty: quantity
              )
            end

          end
        end
      end
      logger.debug("===== End FBA check =====\n")
      logger.debug("======= LISTING REPORT ========")

      report_type = "_GET_MERCHANT_LISTINGS_ALL_DATA_"

      client = MWS.reports(
        marketplace: marketplace_id,
        merchant_id: seller_id,
        aws_access_key_id: aws_access_key_id,
        aws_secret_access_key: secret_key
      )

      response = client.request_report(report_type)
      parser = response.parse
      reqid = parser.dig('ReportRequestInfo', 'ReportRequestId')

      mws_options = {
        report_request_id_list: reqid,
      }
      process = ""
      logger.debug(reqid)
      while process != "_DONE_" && process != "_DONE_NO_DATA_"
        response = client.get_report_request_list(mws_options)
        parser = response.parse
        process = parser.dig('ReportRequestInfo', 'ReportProcessingStatus')
        logger.debug(process)
        if process == "_DONE_" then
          genid = parser.dig('ReportRequestInfo', 'GeneratedReportId')
          break
        elsif process == "_DONE_NO_DATA_" then
          genid = "NODATA"
          break
        end
        sleep(5)
      end

      if genid.to_s != "NODATA" then
        response = client.get_report(genid)
        parser = response.parse
        logger.debug("====== report data is ok =======")
        logger.debug(parser)

        asin_hash = Hash.new

        parser.each do |row|
          tsku = row[2].to_s
          tasin = row[11].to_s
          quantity = row[4].to_i
          if asin_hash.has_key?(tasin) == true then
            temp = asin_hash[tasin]
            quantity = quantity.to_i + temp[2].to_i
            asin_hash[tasin] = [tasin, tsku, quantity]
          else
            asin_hash[tasin] = [tasin, tsku, quantity]
          end

          if asins.include?(tasin) then
            logger.debug("ASIN: " + tasin + " ,FBA stock: " + quantity.to_s)
            target = stocks.find_or_create_by(
              product_id: tasin,
              recorded_at: Date.today
            )
            target.update(
              self_qty: quantity
            )
          end
        end

      end

    end

    asins.each do |asin|
      t = stocks.where(product_id: asin).order("recorded_at DESC NULLS LAST").first
      t2 = stocks.where(product_id: asin).order("recorded_at DESC NULLS LAST").second
      if t != nil then
        if t2 != nil then
          t.update(
            total_qty: t.fba_qty.to_i + t.self_qty.to_i,
            arriving_qty: t2.arriving_qty.to_i
          )
        else
          t.update(
            total_qty: t.fba_qty.to_i + t.self_qty.to_i,
            arriving_qty: 0
          )
        end
      end
    end

  end


end
