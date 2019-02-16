class ProductStocksController < ApplicationController
  require 'rubyXL'
  require 'peddler'

  before_action :authenticate_user!

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url, :alert => exception.message
  end

  def edit
    @login_user = current_user
    user = current_user.email
    @headers = Constants::CONV_PSTOCK
    inv_headers = @headers.invert
    @product_stocks = ProductStock.where(user: user).order("recorded_at DESC NULLS LAST").order("total_qty DESC")
    @counter = ProductStock.where(user: user).group(:product_id).count
    @products = Product.where(user: user)
    @product_id = params[:product_id]
    if @product_id != nil then
      @product_stocks = @product_stocks.where(product_id: @product_id).order("recorded_at DESC NULLS LAST")
    else

    end
    if request.post? then
      #ProductStock.get_report(user)
      GetReportJob.perform_later(user)
    end

  end

  def template
    respond_to do |format|
      format.html
      format.xlsx do
        @workbook = RubyXL::Workbook.new
        @sheet = @workbook.first
        user = current_user.email

        headers = {
          product_id: "商品コード",
          title: "商品名",
          on_delivery_quantity: "出庫数"
        }

        inv_headers = headers.invert

        product_stocks = ProductStock.where(user: user)

        headers.each_with_index do |(key, value), index|
          @sheet.add_cell(0, index, value)
        end

        product_stocks.each_with_index do |stock, row|
          if ProductStock.title == nil then
            product_id = ProductStock.product_id
            product = Product.find_by(user: user, product_id: product_id)
            if product != nil then
              title = product.title
              ProductStock.update(
                title: title
              )
            end
          end
          headers.each_with_index do |(key, value), col|
            @sheet.add_cell(1 + row, col, stock[key])
          end
        end

        data = @workbook.stream.read
        timestamp = Time.new.strftime("%Y%m%d%H%M%S")
        send_data data, filename: "商品出庫テンプレート_" + timestamp + ".xlsx", type: "application/xlsx", disposition: "attachment"
      end
    end
  end

  def output
    respond_to do |format|
      format.html
      format.xlsx do
        @workbook = RubyXL::Workbook.new
        @sheet = @workbook.first
        user = current_user.email
        headers = Constants::CONV_MSTOCK

        headers.each_with_index do |(key, value), index|
          @sheet.add_cell(0, index, value)
        end

        code = params[:code]
        if code != nil then
          materials = MaterialProductStock.where(user: user, code: code)
        else
          materials = MaterialProductStock.where(user: user)
        end
        materials.each_with_index do |material, row|

          headers.each_with_index do |(key, value), col|
            logger.debug(material[key])
            @sheet.add_cell(1 + row, col, material[key].to_s)
          end
        end

        data = @workbook.stream.read
        timestamp = Time.new.strftime("%Y%m%d%H%M")
        send_data data, filename: "商品在庫データ_" + timestamp + ".xlsx", type: "application/xlsx", disposition: "attachment"

      end
    end
  end

  def regist
    if request.post? then
      data = params[:product_ship]
      if data != nil then
        ext = File.extname(data.path)
        if ext == ".xlsx" then
          workbook = RubyXL::Parser.parse(data.path)
          worksheet = workbook.first
          sheet_header = worksheet.sheet_data[0]
          logger.debug("====== HEADER CHECK =========")
          header_check = true
          @headers = {
            product_id: "商品コード",
            title: "商品名",
            on_delivery_quantity: "出庫数"
          }
          @headers.each_with_index do |head, index|
            if sheet_header[index] != nil then
              name = sheet_header[index].value
              if @headers.has_value?(name) == false then
                header_check = false
              end
            else
              header_check = false
            end
          end

          if header_check == true then
            logger.debug("====== HEADER OK =========")
          else
            logger.debug("====== HEADER NG =========")
            return
          end

          inv_headers = @headers.invert
          user = current_user.email
          product_stocks = ProductStock.where(user: user)
          recipes = Recipe.where(user: user)
          mproduct_stocks = MaterialProductStock.where(user: user)

          worksheet.each_with_index do |row, index|
            if index > 0 then
              logger.debug("====== ROW " + index.to_s  + " =========")
              input_row = Hash.new
              @headers.each_with_index do |head, col|
                name = sheet_header[col].value
                key = inv_headers[name]
                if row[col] != nil then
                  value = row[col].value
                else
                  value = nil
                end
                input_row[key] = value
              end
              product_id = input_row[:product_id]
              quantity = input_row[:on_delivery_quantity]
              target = product_stocks.find_by(product_id: product_id)
              if target != nil then
                current = target.on_delivery_quantity
                if (current - quantity) >= 0 then
                  target.update(
                    on_delivery_quantity: (current - quantity)
                  )
                end
              end

              if quantity > 0 then
                MaterialProductStock.new.ship(user, product_id, quantity)
              end
              input_row = nil
            end
          end

        end
      end
    end
    redirect_to product_stocks_edit_path
  end

end
