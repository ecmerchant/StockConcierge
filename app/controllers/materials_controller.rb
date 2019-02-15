class MaterialsController < ApplicationController

  require 'rubyXL'

  before_action :authenticate_user!

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url, :alert => exception.message
  end

  def edit
    @login_user = current_user
    user = current_user.email
    @material_id = params[:material_id]
    @total = Material.where(user: user).count
    if @material_id == nil then
      @materials = Material.where(user: user).order('name COLLATE "C" ASC')
    else
      @materials = Material.where(user: user, material_id: @material_id).order('name COLLATE "C" ASC')
    end
    @headers = Constants::CONV_MATERIAL
    inv_headers = @headers.invert
    if request.post? then
      data = params[:material_data]
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

          materials = Array.new
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
                #logger.debug("key: " + key.to_s + ", value: " + value.to_s)
                input_row[key] = value
              end
              input_row[:user] = user
              if input_row[:material_id] != nil then
                logger.debug(input_row)
                materials << Material.new(input_row)
              end
              input_row = nil
            end
          end

          target_cols = @headers.keys
          target_cols.delete_at(0)
          logger.debug(target_cols)
          Material.import materials, on_duplicate_key_update: {constraint_name: "for_upsert_materials", columns: target_cols}

        end
      end
    end

  end

  def delete
    @login_user = current_user
    user = current_user.email
    @materials = Material.where(user: user)
    @headers = Constants::CONV_MATERIAL
    inv_headers = @headers.invert
    if request.post? then
      data = params[:material_delete_data]
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
                tag = @materials.find_by(code: code)
                if tag != nil then
                  tag.delete
                end
              end
            end
          end
        end
      end
    end
    redirect_to materials_edit_path
  end

  def template
    user = current_user.email
    respond_to do |format|
      format.html
      format.xlsx do
        @workbook = RubyXL::Workbook.new
        @sheet = @workbook.first

        headers = Constants::CONV_MATERIAL

        headers.each_with_index do |(key, value), index|
          @sheet.add_cell(0, index, value)
        end

        categories = Category.where(user: user)
        suppliers = Supplier.where(user: user)

        @sheet.add_cell(0, 12,"カテゴリー")
        @sheet.add_cell(0, 13,"カテゴリー名")

        categories.each_with_index do |cat, index|
          @sheet.add_cell(1 + index, 12, cat.category_id)
          @sheet.add_cell(1 + index, 13, cat.name)
        end


        @sheet.add_cell(0, 15,"仕入れ先")
        @sheet.add_cell(0, 16,"仕入れ先名")

        suppliers.each_with_index do |sup, index|
          @sheet.add_cell(1 + index, 15, sup.supplier_id)
          @sheet.add_cell(1 + index, 16, sup.name)
        end

        data = @workbook.stream.read
        timestamp = Time.new.strftime("%Y%m%d%H%M%S")
        send_data data, filename: "素材マスタ入力テンプレート_" + timestamp + ".xlsx", type: "application/xlsx", disposition: "attachment"
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
        headers = Constants::CONV_MATERIAL

        headers.each_with_index do |(key, value), index|
          @sheet.add_cell(0, index, value)
        end

        materials = Material.where(user: user)

        materials.each_with_index do |material, row|
          headers.each_with_index do |(key, value), col|
            @sheet.add_cell(1 + row, col, material[key])
          end
        end

        data = @workbook.stream.read
        timestamp = Time.new.strftime("%Y%m%d%H%M%S")
        send_data data, filename: "素材データ_" + timestamp + ".xlsx", type: "application/xlsx", disposition: "attachment"

      end
    end
  end

  def replace
    @login_user = current_user
    user = current_user.email
    @materials = Material.where(user: user).order('name COLLATE "C" ASC')
    @headers = Constants::CONV_MATERIAL
    inv_headers = @headers.invert
    if request.post? then
      data = params[:material_data]
      if data != nil then
        ext = File.extname(data.path)
        if ext == ".xlsx" then
          workbook = RubyXL::Parser.parse(data.path)
          worksheet = workbook.first
          sheet_header = worksheet.sheet_data[0]
          logger.debug("====== HEADER CHECK =========")
          header_check = true

          @headers = {
            before_code: "入替前：素材コード",
            before_name: "入替前：素材名",
            after_code: "入替後：素材コード",
            after_name: "入替後：素材名"
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

          recipes = Recipe.where(user: user)
          mstocks = MaterialStock.where(user: user)
          mats = Material.where(user: user)

          materials = Array.new
          worksheet.each_with_index do |row, index|
            if index > 0 then
              logger.debug("====== ROW " + index.to_s  + " =========")
              if row[0] == nil then
                break
              else
                before_code = row[0].value
                if row[2] != nil then
                  after_code = row[0].value
                  recipes_t = recipes.where(material_code: before_code)
                  recipes_t.update(
                    material_code: after_code
                  )
                  st = mstocks.find_by(code: before_code, expire: nil)
                  if st != nil then
                    mt = mats.find_by(code: before_code)
                    sy = (st.ship_reserve_case * mt.package_per_case + st.ship_reserve_package) * mt.quantity_per_package + st.ship_reserve_quantity

                    targets = mstocks.where(code: after_code).order("expire ASC NULLS LAST")
                    temp_mat = mats.find_by(code: after_code)

                    package_per_case = temp_mat.package_per_case
                    quantity_per_package = temp_mat.quantity_per_package

                    add_ship_reserve_total = sy

                    targets.each do |target|
                      current_total = target.case.to_i * (package_per_case * quantity_per_package) + target.package.to_i * quantity_per_package + target.quantity.to_i
                      ship_reserve_total  = target.ship_reserve_case.to_i * (package_per_case * quantity_per_package) + target.ship_reserve_package.to_i * quantity_per_package + target.ship_reserve_quantity.to_i

                      if current_total > add_ship_reserve_total + ship_reserve_total then
                        new_ship_reserve_total = add_ship_reserve_total + ship_reserve_total
                        new_ship_reserve_case = new_ship_reserve_total.div(package_per_case * quantity_per_package)
                        new_ship_reserve_package = (new_ship_reserve_total % (package_per_case * quantity_per_package)).div(quantity_per_package)
                        new_ship_reserve_quantity = (new_ship_reserve_total % (package_per_case * quantity_per_package))%(quantity_per_package)

                        target.update(
                          ship_reserve_case: new_ship_reserve_case,
                          ship_reserve_package: new_ship_reserve_package,
                          ship_reserve_quantity: new_ship_reserve_quantity,
                          ship_reserve_date: Date.today
                        )

                        break
                      else

                        new_ship_reserve_total = current_total
                        new_ship_reserve_case = new_ship_reserve_total.div(package_per_case * quantity_per_package)
                        new_ship_reserve_package = (new_ship_reserve_total % (package_per_case * quantity_per_package)).div(quantity_per_package)
                        new_ship_reserve_quantity = (new_ship_reserve_total % (package_per_case * quantity_per_package))%(quantity_per_package)

                        target.update(
                          ship_reserve_case: new_ship_reserve_case,
                          ship_reserve_package: new_ship_reserve_package,
                          ship_reserve_quantity: new_ship_reserve_quantity,
                          ship_reserve_date: Date.today
                        )

                        add_ship_reserve_total = add_ship_reserve_total + ship_reserve_total - current_total
                      end
                    end
                    st.delete
                  end
                end
              end
            end
          end

        end
      end
    end
  end

  def replace_template
    respond_to do |format|
      format.html
      format.xlsx do
        @workbook = RubyXL::Workbook.new
        @sheet = @workbook.first

        materials = Material.where(user: current_user.email).order("name ASC")

        @sheet.add_cell(0, 0, "入替前：素材コード")
        @sheet.add_cell(0, 1, "入替前：素材名")

        @sheet.add_cell(0, 2, "入替後：素材コード")
        @sheet.add_cell(0, 3, "入替後：素材名")

        @sheet.add_cell(0, 6, "参考")
        @sheet.add_cell(0, 7, "素材コード")
        @sheet.add_cell(0, 8, "素材名")

        materials.each_with_index do |material, index|
          @sheet.add_cell(1 + index, 7, material.code)
          @sheet.add_cell(1 + index, 8, material.name)
        end

        data = @workbook.stream.read
        timestamp = Time.new.strftime("%Y%m%d%H%M%S")
        send_data data, filename: "素材入替テンプレート_" + timestamp + ".xlsx", type: "application/xlsx", disposition: "attachment"
      end
    end
  end

end
