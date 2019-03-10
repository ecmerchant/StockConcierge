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
          name: "商品名",
          input_qty: "入庫数"
        }

        inv_headers = headers.invert

        product_stocks = ProductStock.where(user: user)

        headers.each_with_index do |(key, value), index|
          @sheet.add_cell(0, index, value)
        end

        Product.where(user: user).each_with_index do |stock, row|
          @sheet.add_cell(1 + row, 0, stock.product_id)
          @sheet.add_cell(1 + row, 1, stock.name)
          @sheet.add_cell(1 + row, 2, 0)
        end

        data = @workbook.stream.read
        timestamp = Time.new.strftime("%Y%m%d%H%M%S")
        send_data data, filename: "商品入庫テンプレート_" + timestamp + ".xlsx", type: "application/xlsx", disposition: "attachment"
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
            name: "商品名",
            input_qty: "入庫数"
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
          mproduct_stocks = MaterialStock.where(user: user)

          new_workbook = RubyXL::Workbook.new
          new_worksheet = new_workbook.first
          mheaders = Constants::CONV_MATERIAL
          mheaders.each_with_index do |(key, value), index|
            new_worksheet.add_cell(0, index, value)
          end
          mcounter = 0

          worksheet.each_with_index do |row, index|
            if index > 0 then
              logger.debug("====== ROW " + index.to_s  + " =========")

              product_id = row[0].value
              if row[2] != nil then
                quantity = row[2].value
              else
                quantity = 0
              end
              target = product_stocks.find_by(product_id: product_id)
              if target != nil then
                current = target.arriving_qty
                if (current - quantity) >= 0 then
                  target.update(
                    arriving_qty: (current - quantity)
                  )
                end
              end

              if quantity > 0 then
                #素材の出庫登録
                new_worksheet = new_workbook.add_worksheet('product_id')
                trecipe = recipes.where(product_id: product_id)
                trecipe.each do |tp|
                  material_id = tp.material_id
                  required_qty = tp.required_qty * quantity
                  tmat = MaterialStock.where(user: user, material_id: material_id).where.not(expire: nil).order("expire ASC NULLS LAST")

                  tmat.each do |tt|
                    if tt.current_total >= required_qty then
                      data = MaterialStock.calc_ship(user, material_id, required_qty)
                      mcounter += 1
                      new_worksheet.add_cell(mcounter, 0, material_id)
                      new_worksheet.add_cell(mcounter, 1, tp.material.name)
                      new_worksheet.add_cell(mcounter, 2, tp.material.category.name)
                      new_worksheet.add_cell(mcounter, 3, "出庫")
                      new_worksheet.add_cell(mcounter, 4, tt.expire.strftime("%Y/%M/%D"))
                      new_worksheet.add_cell(mcounter, 5, data[0])
                      new_worksheet.add_cell(mcounter, 6, data[1])
                      new_worksheet.add_cell(mcounter, 7, data[2])
                      break
                    else
                      data = MaterialStock.calc_ship(user, material_id, required_qty)
                      mcounter += 1
                      new_worksheet.add_cell(mcounter, 0, material_id)
                      new_worksheet.add_cell(mcounter, 1, tp.material.name)
                      new_worksheet.add_cell(mcounter, 2, tp.material.category.name)
                      new_worksheet.add_cell(mcounter, 3, "出庫")
                      new_worksheet.add_cell(mcounter, 4, tt.expire.strftime("%Y/%M/%D"))
                      new_worksheet.add_cell(mcounter, 5, tt.current_case)
                      new_worksheet.add_cell(mcounter, 6, tt.current_package)
                      new_worksheet.add_cell(mcounter, 7, tt.current_qty)
                    end
                  end
                end
              end
            end
          end

          data = new_workbook.stream.read
          timestamp = Time.new.strftime("%Y%m%d%H%M")
          send_data data, filename: "素材出庫確認用データ_" + timestamp + ".xlsx", type: "application/xlsx", disposition: "attachment"

        end
      end
    end
    redirect_to product_stocks_edit_path
  end

end
