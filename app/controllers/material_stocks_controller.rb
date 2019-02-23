class MaterialStocksController < ApplicationController

  require 'rubyXL'

  before_action :authenticate_user!

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url, :alert => exception.message
  end

  def edit
    @login_user = current_user
    user = current_user.email
    @target_code = params[:material_id]
    if @target_code != nil then
      @headers = Constants::CONV_MSTOCK_D
      inv_headers = @headers.invert
      temp = MaterialStock.where(user: user, material_id: @target_code).where.not(expire: nil).where("current_total > 0")
      @materials = temp.order("expire ASC NULLS LAST")
      @material = @materials.first
      @mat_name = @material.material.name

      @total_num = temp.sum(:current_total)
      @total_case = temp.sum(:current_case)
      @total_package = temp.sum(:current_package)
      @total_quantity = temp.sum(:current_qty)

      tt = MaterialStock.where(user: user, material_id: @target_code, expire: nil).order("created_at DESC NULLS LAST").first
      @arriving_total = tt.arriving_total
      @shipping_total = tt.shipping_total
    else
      @headers = Constants::CONV_MSTOCK
      inv_headers = @headers.invert
      @materials = MaterialStock.where(user: user, expire: nil).order("created_at DESC NULLS LAST")
    end

    if request.post? then
      data = params[:materials_input_data]
      if data != nil then
        ext = File.extname(data.path)
        if ext == ".xlsx" then
          workbook = RubyXL::Parser.parse(data.path)
          worksheet = workbook.first
          sheet_header = worksheet.sheet_data[0]
          logger.debug("====== HEADER CHECK =========")
          header_check = true

          headers = {
            material_id: "素材コード",
            name: "素材名",
            category_id: "カテゴリー",
            action: "登録種別",
            expire: "賞味期限",
            input_case: "登録ケース数",
            input_package: "登録パッケージ数",
            input_qty: "登録バラ数"
          }

          inv_headers = headers.invert

          headers.each_with_index do |head, index|
            if sheet_header[index] != nil then
              name = sheet_header[index].value
              if headers.has_value?(name) == false then
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

          material_stocks = Array.new
          worksheet.each_with_index do |row, index|
            if index > 0 then
              logger.debug("====== ROW " + index.to_s  + " =========")
              if row != nil then
                input_row = Hash.new
                headers.each_with_index do |head, col|
                  name = sheet_header[col].value
                  key = inv_headers[name]
                  if row[col] != nil then
                    value = row[col].value
                  else
                    value = nil
                    if name == "登録パッケージ数" || name == "登録ケース数" || name == "登録バラ数" then
                      value = 0
                    end
                  end
                  if key != :name && key != :category_id then
                    input_row[key] = value
                  end
                end
                input_row[:user] = user
                if input_row[:material_id] != nil && input_row[:action] != nil then
                  MaterialStock.stock_update(user, input_row[:material_id], input_row[:action], input_row[:expire], input_row[:input_case], input_row[:input_package], input_row[:input_qty])
                end
              end 
              input_row = nil
            end
          end
        end
      end
      redirect_back(fallback_location: root_path)
    end
  end

  def template
    respond_to do |format|
      format.html
      format.xlsx do
        @workbook = RubyXL::Workbook.new
        @sheet = @workbook.first

        headers = {
          material_id: "素材コード",
          name: "素材名",
          category_id: "カテゴリー",
          action: "登録種別",
          expire: "賞味期限",
          input_case: "登録ケース数",
          input_package: "登録パッケージ数",
          input_qty: "登録バラ数"
        }
        user = current_user.email
        inv_headers = headers.invert

        headers.each_with_index do |(key, value), index|
          @sheet.add_cell(0, index, value)
        end

        materials = Material.where(user: user)

        materials.each_with_index do |material, index|
          headers.each_with_index do |(key, value), col|
            if col != 2 then
              @sheet.add_cell(1 + index, col, material[key])
            else
              @sheet.add_cell(1 + index, col, material.category.name)
            end
          end
        end

        timestamp = Time.new.strftime("%Y%m%d%H%M%S")
        data = @workbook.stream.read
        send_data data, filename: "素材入出庫用テンプレート_" + timestamp + ".xlsx", type: "application/xlsx", disposition: "attachment"
      end
    end
  end

  def inventory
    respond_to do |format|
      format.html
      format.xlsx do
        @workbook = RubyXL::Workbook.new
        @sheet = @workbook.first
        user = current_user.email
        material_stocks = MaterialStock.where(user: user)
        materials = Material.where(user: user)

        headers = {
          material_id: "素材コード",
          name: "素材名",
          category_id: "カテゴリー",
          action: "登録種別",
          expire: "賞味期限",
          input_case: "登録ケース数",
          input_package: "登録パッケージ数",
          input_qty: "登録バラ数"
        }
        user = current_user.email
        inv_headers = headers.invert

        headers.each_with_index do |(key, value), index|
          @sheet.add_cell(0, index, value)
        end
        row = 0
        materials.each_with_index do |material, index|
          temp = material_stocks.where(material_id: material.material_id).where.not(expire: nil)
          tag = temp.group(:expire).pluck(:expire)
          tag.each do |t|
            if t != nil then
              s = temp.where(expire: t).order("created_at DESC NULLS LAST").first

              @sheet.add_cell(1 + row, 0, material.material_id)
              @sheet.add_cell(1 + row, 1, material.name)
              @sheet.add_cell(1 + row, 2, material.category.name)
              @sheet.add_cell(1 + row, 3, "棚卸")
              @sheet.add_cell(1 + row, 4, s.expire.strftime("%Y/%m/%d"))
              @sheet.add_cell(1 + row, 5, s.current_case)
              @sheet.add_cell(1 + row, 6, s.current_package)
              @sheet.add_cell(1 + row, 7, s.current_qty)
              row += 1
            end
          end
        end

        timestamp = Time.new.strftime("%Y%m%d%H%M%S")
        data = @workbook.stream.read
        send_data data, filename: "素材棚卸用テンプレート_" + timestamp + ".xlsx", type: "application/xlsx", disposition: "attachment"
      end
    end
  end

  def delete
    code = params[:id]
    if code != nil then
      target = MaterialStock.find(code)
      if target != nil then
        target.delete
      end
    end
    redirect_back(fallback_location: root_path)
  end

end
