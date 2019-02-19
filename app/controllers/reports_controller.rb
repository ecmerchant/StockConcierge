class ReportsController < ApplicationController
  require 'rubyXL'

  before_action :authenticate_user!

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url, :alert => exception.message
  end

  def edit
    @login_user = current_user
    user = current_user.email
    @count = Product.where(user: user).group(:product_id).count

    @product_id = params[:product_id]
    if @product_id != nil then
      @reports = Report.where(user: user, product_id: @product_id)
      @title = Product.find_by(user: user, product_id: @product_id).name
    else
      @reports = Report.where(user: user)
    end
    @headers = Constants::CONV_REPORT
    inv_headers = @headers.invert
    if request.post? then
      data1 = params[:business_data]
      data2 = params[:adv_data]
      if data1 != nil then
        logger.debug("=========")
        ext = File.extname(data1.path)
        fname = data1.original_filename

        dt = fname.match(/^([\s\S]*?)_/)[1]
        logger.debug(dt)
        adt = Date.strptime(dt, '%Y%m%d')
        logger.debug(adt)
        if ext == ".csv" then
          bls = Array.new
          csv_data = CSV.read(data1.path, 'r:BOM|UTF-8', headers: true)
          csv_data.each do |data|
            temp = Hash.new
            asin = data[1]
            logger.debug(data)
            if asin != nil then
              target = Report.find_or_create_by(
                user: user,
                product_id: asin,
                recorded_at: adt
              )
              target.update(
                session: data[3].gsub(",", "").to_i,
                session_rate: data[4],
                page_view: data[5].gsub(",", "").to_i,
                page_view_rate: data[6],
                cart_box_rate: data[7],
                order_quantity: data[8].gsub(",", "").to_i,
                unit_session_rate: data[9],
                sale: data[12].gsub(",", "").gsub("￥", "").to_i,
                total: data[14]
              )
            end
            temp = nil
          end
        end
      end

      if data2 != nil then
        logger.debug("====== ADV1 =========")
        ext = File.extname(data2.path)
        if ext == ".xlsx" then
          workbook = RubyXL::Parser.parse(data2.path)
          worksheet = workbook.first
          sheet_header = worksheet.sheet_data[0]
          logger.debug("====== HEADER CHECK =========")
          header_check = true
          @headers[:product_id] = "宣伝 ASIN"
          @headers[:recorded_at] = "データ取得日"

          if sheet_header[6].value == "宣伝 ASIN" then
            header_check = true
          else
            header_check = false
          end

          if header_check == true then
            logger.debug("====== HEADER OK =========")
          else
            logger.debug("====== HEADER NG =========")
            return
          end
          advs = Array.new
          target_cols = nil
          worksheet.each_with_index do |row, index|
            if index > 0 then
              logger.debug("====== ROW " + index.to_s  + " =========")
              if row[0] != nil then
                asin = row[6].value
                adt = row[0].value
                if asin != nil then
                  target = Report.find_or_create_by(
                    user: user,
                    product_id: asin,
                    recorded_at: adt
                  )

                  target.update(
                    :impression => row[7].value.to_f.round(0),
                    :click => row[8].value.to_f.round(0),
                    :click_through_rate => row[9].value.to_f.round(3),
                    :click_per_cost => row[10].value.to_f.round(1),
                    :cost => row[11].value,
                    :total_sale => row[12].value,
                    :adv_cost_of_sale => row[13].value.to_f.round(2),
                    :return_on_adv_spend => row[14].value.to_f.round(2)
                  )
                end
                input_row = nil
              end
            end
          end
        end
      end
    end
  end


  def clear
    @login_user = current_user
    user = current_user.email
    if request.post? then
      target = params[:target_date]
      commit = params[:commit]
      reports = Report.where(user: user, recorded_at: target).delete_all
    end
    redirect_to reports_edit_path
  end

  def output
    respond_to do |format|
      format.html
      format.xlsx do
        @workbook = RubyXL::Workbook.new
        @sheet = @workbook.first
        user = current_user.email
        headers = Constants::CONV_PRODUCT

        headers.each_with_index do |(key, value), index|
          @sheet.add_cell(0, index, value)
        end

        products = Product.where(user: user)

        products.each_with_index do |product, row|
          headers.each_with_index do |(key, value), col|
            logger.debug(product[key])
            @sheet.add_cell(1 + row, col, product[key].to_s)
          end
        end

        data = @workbook.stream.read
        timestamp = Time.new.strftime("%Y%m%d%H%M%S")
        send_data data, filename: "商品データ_" + timestamp + ".xlsx", type: "application/xlsx", disposition: "attachment"

      end
    end
  end

end
