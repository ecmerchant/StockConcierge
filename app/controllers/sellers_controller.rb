class SellersController < ApplicationController
  require 'rubyXL'

  before_action :authenticate_user!

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url, :alert => exception.message
  end

  def edit
    @login_user = current_user
    user = current_user.email
    @sellers = Seller.where(user: user)
    @headers = Constants::CONV_SELLER
    inv_headers = @headers.invert
    if request.post? then
      data = params[:seller_data]
      if data != nil then
        ext = File.extname(data.path)
        if ext == ".xlsx" then
          workbook = RubyXL::Parser.parse(data.path)
          worksheet = workbook.first
          sheet_header = worksheet.sheet_data[0]
          logger.debug("====== HEADER CHECK =========")
          header_check = true

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

          sellers = Array.new
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
              input_row[:user] = user
              if input_row[:seller_id] != nil then
                temp = Seller.find_by(user: user, seller_id: input_row[:seller_id])
                if temp != nil then
                  temp.update(
                    input_row
                  )
                else
                  Seller.create(input_row)
                end
              end
              input_row = nil
            end
          end

          target_cols = @headers.keys
          target_cols.delete_at(1)

        end
      end
    end
  end

  def delete
    @login_user = current_user
    user = current_user.email
    @sellers = Seller.where(user: user)
    @headers = Constants::CONV_SELLER
    inv_headers = @headers.invert
    if request.post? then
      data = params[:supplier_delete_data]
      if data != nil then
        ext = File.extname(data.path)
        if ext == ".xlsx" then
          workbook = RubyXL::Parser.parse(data.path)
          worksheet = workbook.first
          sheet_header = worksheet.sheet_data[0]
          logger.debug("====== HEADER CHECK =========")
          header_check = true

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

          worksheet.each_with_index do |row, index|
            if index > 0 then
              logger.debug("====== ROW " + index.to_s  + " =========")
              if row[0] != nil then
                code = row[0].value
                tag = @sellers.find_by(code: code)
                if tag != nil then
                  tag.delete
                end
              end
            end
          end
        end
      end
    end
    redirect_to sellers_edit_path
  end

  def template
    respond_to do |format|
      format.html
      format.xlsx do
        @workbook = RubyXL::Workbook.new
        @sheet = @workbook.first

        headers = Constants::CONV_SELLER

        headers.each_with_index do |(key, value), index|
          @sheet.add_cell(0, index, value)
        end

        data = @workbook.stream.read
        timestamp = Time.new.strftime("%Y%m%d%H%M%S")
        send_data data, filename: "販売店舗情報テンプレート_" + timestamp + ".xlsx", type: "application/xlsx", disposition: "attachment"
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
        headers = Constants::CONV_SELLER

        headers.each_with_index do |(key, value), index|
          @sheet.add_cell(0, index, value)
        end

        sellers = Seller.where(user: user)

        sellers.each_with_index do |material, row|
          headers.each_with_index do |(key, value), col|
            @sheet.add_cell(1 + row, col, material[key])
          end
        end

        data = @workbook.stream.read
        timestamp = Time.new.strftime("%Y%m%d%H%M%S")
        send_data data, filename: "販売店舗情報_" + timestamp + ".xlsx", type: "application/xlsx", disposition: "attachment"

      end
    end
  end
end
