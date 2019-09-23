class ProductsController < ApplicationController

  require 'rubyXL'
  require "time"
  require "csv"

  before_action :authenticate_user!

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url, :alert => exception.message
  end

  def show
    @login_user = current_user
    user = current_user.email
    @products = Product.where(user: user)
    @stocks = ProductStock.where(user: user)
    @materials = Material.where(user: user)
    @recipes = Recipe.where(user: user)
    @reports = Report.where(user: user)
    @headers = {
      asin: "商品コード",
      title: "商品名",
      recipe: "レシピ",
      stock: "在庫状況",
      report: "売れ行き",
      fba_quantity: "FBA在庫",
      self_quantity: "自社在庫",
      on_delivery_quantity: "入荷予定在庫",
      price: "販売価格",
      cost: "原価",
      profit: "見込み利益",
      sales: "売れ行き（14日間）",
      adv_cost: "広告費（14日間）"
    }

    if request.post? then
      data = params[:material_pick]
      if data != nil then
        ext = File.extname(data.path)
        if ext == ".xlsx" then
          workbook = RubyXL::Parser.parse(data.path)
          worksheet = workbook.first
          sheet_header = worksheet.sheet_data[0]
          logger.debug("====== HEADER CHECK =========")
          header_check = true

          theader = {
            material_id: "素材コード",
            name: "素材名",
            expire: "賞味期限",
            required_qty: "必要総数量",
            location_id: "ロケーション",
            checked: "チェック"
          }

          theader.each_with_index do |head, index|
            if sheet_header[index] != nil then
              name = sheet_header[index].value
              if theader.has_value?(name) == false then
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
              buf = Array.new
              for num in 0..5  do
                if row[num] != nil then
                  buf[num] = row[num].value
                else
                  buf[num] = nil
                end
              end
              checked = buf[5]
              if checked != "" && checked != nil then
                logger.debug("--------------")
                material_id = buf[0]
                expire = buf[2]
                req = buf[3].to_i
                logger.debug(material_id)
                logger.debug(expire)
                logger.debug(req)
                temp = MaterialStock.calc_ship(user, material_id, req)

                action = "出庫"
                MaterialStock.stock_update(user, material_id, action, expire, temp[0].to_i, temp[1].to_i, temp[2].to_i)
              end
            end
          end
        end
      end
    end
  end

  def edit
    @login_user = current_user
    user = current_user.email
    @products = Product.where(user: user)
    @materials = Material.where(user: user)
    @recipes = Recipe.where(user: user)
    @headers = Constants::CONV_PRODUCT
    inv_headers = @headers.invert
    if request.post? then
      data = params[:product_data]
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

          products = Array.new
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
              input_row[:cost] = 0
              input_row[:profit] = 0

              input_row[:user] = user

              if input_row[:product_id] != nil then
                temp = Product.find_by(user: user, product_id: input_row[:product_id])
                if temp != nil then
                  temp.update(
                    input_row
                  )
                else
                  Product.create(input_row)
                end
              end
              input_row = nil
            end
          end

        end
      end
    end
  end

  def delete
    @login_user = current_user
    user = current_user.email
    @products = Product.where(user: user)
    @headers = Constants::CONV_PRODUCT
    inv_headers = @headers.invert
    if request.post? then
      data = params[:product_delete_data]
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
                asin = row[0].value
                tag = @products.find_by(asin: asin)
                if tag != nil then
                  tag.delete
                end
              end
            end
          end
        end
      end
    end
    redirect_to products_edit_path
  end

  def template
    user = current_user.email
    respond_to do |format|
      format.html
      format.xlsx do
        @workbook = RubyXL::Workbook.new
        @sheet = @workbook.first

        headers = Constants::CONV_PRODUCT

        headers.each_with_index do |(key, value), index|
          @sheet.add_cell(0, index, value)
        end

        @sheet.add_cell(0, 12,"店舗")
        @sheet.add_cell(0, 13,"店舗名")

        sellers = Seller.where(user: user)

        sellers.each_with_index do |sell, index|
          @sheet.add_cell(1 + index, 12, sell.seller_id)
          @sheet.add_cell(1 + index, 13, sell.name)
        end

        data = @workbook.stream.read
        timestamp = Time.new.strftime("%Y%m%d%H%M%S")
        send_data data, filename: "商品マスタ入力テンプレート_" + timestamp + ".xlsx", type: "application/xlsx", disposition: "attachment"
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


  def check
    @login_user = current_user
    user = current_user.email
    @products = Product.where(user: user)
    @materials = Material.where(user: user)
    @tag_materials = Material.where(user: user)
    @recipes = Recipe.where(user: user)

    @headers1 = {
      product_id: "商品コード",
      check_quantity: "必要数量",
      name: "商品名",
      min_expire: "最短賞味期限"
    }

    @headers2 = {
      material_id: "素材コード",
      check_quantity: "必要数量",
      name: "素材名",
      total_quantity: "総在庫（納品予定含む）",
      substract_quantity: "数量の過不足"
    }

    inv_headers1 = @headers1.invert
    inv_headers2 = @headers2.invert

    @material_stocks = MaterialStock.where(user: user)

    @calc_products = nil
    @calc_materials = nil
    @required_materials = nil

    if request.post? then
      data = params[:product_check_data]
      if data != nil then
        ext = File.extname(data.path)
        if ext == ".xlsx" then
          workbook = RubyXL::Parser.parse(data.path)
          worksheet = workbook.first
          sheet_header = worksheet.sheet_data[0]
          logger.debug("====== HEADER CHECK =========")
          logger.debug(sheet_header)
          header_check = true

          cheaders1 = {
            product_id: "商品コード",
            check_quantity: "必要数量",
            name: "商品名"
          }

          cheaders1.each_with_index do |head, index|
            if sheet_header[index] != nil then
              name = sheet_header[index].value
              if cheaders1.has_value?(name) == false then
                header_check = false
              end
            else
              header_check = false
            end
          end

          if header_check == true then
            logger.debug("====== HEADER OK! =========")
          else
            logger.debug("====== HEADER NG =========")
            return
          end

          @calc_products = Array.new
          @calc_materials = Array.new

          @required_materials = Hash.new
          @recipes = Recipe.where(user: user)

          worksheet.each_with_index do |row, index|
            if index > 0 then
              logger.debug("====== ROW " + index.to_s  + " =========")
              input_row = Hash.new
              cheaders1.each_with_index do |head, col|
                name = sheet_header[col].value
                key = inv_headers1[name]
                if row[col] != nil then
                  value = row[col].value
                else
                  value = nil
                end
                input_row[key] = value
              end

              if input_row[:product_id] != nil then
                if input_row[:check_quantity] > 0 then
                  recipe = @recipes.where(product_id: input_row[:product_id])
                  temp_hash = Hash.new
                  expires = Array.new
                  recipe.each do |buf|
                    temp_hash[buf.material_id] = buf.required_qty * input_row[:check_quantity]
                    tp = MaterialStock.where(user: user, material_id: buf.material_id).order("expire ASC NULLS LAST").first
                    if tp != nil then
                      expire = tp.expire
                      if tp.expire != nil then
                        expires.push(expire)
                      end
                    end
                  end
                  if index == 1 then
                    @required_materials = temp_hash
                  else
                    @required_materials = @required_materials.merge(temp_hash){|key, v1, v2| v1 + v2}
                  end
                  if expires != nil then
                    input_row[:min_expire] = expires.min
                    @calc_products << input_row
                  end

                end
              end
              input_row = nil
            end
          end

          materials = Material.where(user: user)
          @required_materials.each do |key, value|
            if value != 0 && value != nil then
              buf = @material_stocks.where(material_id: key, expire: nil).order("created_at DESC NULLS LAST").first
              hash = Hash.new
              if buf != nil then
                hash = {
                  material_id: key,
                  check_quantity: value.to_i,
                  name: buf.material.name,
                  total_quantity: buf.current_total.to_i + buf.arriving_total.to_i,
                  substract_quantity: buf.current_total.to_i + buf.arriving_total.to_i - value.to_i
                }
              else
                hash = {
                  material_id: key,
                  check_quantity: value.to_i,
                  name: materials.find_by(material_id: key).name,
                  total_quantity: 0,
                  substract_quantity: 0 - value.to_i
                }
              end
              @calc_materials.push(hash)
            end
          end

          @calc_materials.sort_by! {|a| a[:substract_quantity]}
          @calc_products = @calc_products.sort_by{|a| a[:check_quantity]}.reverse!
          pstocks = ProductStock.where(user: user)
          @calc_products.each do |tp|
            pid = tp[:product_id]
            num = tp[:check_quantity]
            tag = pstocks.where(product_id: pid).order("created_at DESC NULLS LAST").first
            if tag != nil then
              tag.update(
                arriving_qty: tag.arriving_qty.to_i + num.to_i
              )
            end
          end

        end
      end
    end
  end

  def check_output
    if request.post? then
      @workbook = RubyXL::Workbook.new
      @sheet = @workbook.first
      user = current_user.email
      tag = JSON.parse(params[:data])
      tp = JSON.parse(params[:data_product])
      headers = {
        material_id: "素材コード",
        check_quantity: "必要数量",
        name: "素材名",
        total_quantity: "総在庫（納品予定含む）",
        substract_quantity: "数量の過不足"
      }
      if tag == nil then return end

      @sheet.add_cell(0, 0, "発注ASIN")
      @sheet.add_cell(0, 1, "商品名")
      @sheet.add_cell(0, 2, "数量")
      @sheet.add_cell(0, 3, "最短賞味期限")
      ps = ProductStock.where(user: user)
      tp.each_with_index do |tt, index|
        @sheet.add_cell(1 + index, 0, tt["product_id"])
        @sheet.add_cell(1 + index, 1, tt["name"])
        @sheet.add_cell(1 + index, 2, tt["check_quantity"])
        @sheet.add_cell(1 + index, 3, tt["min_expire"])
        pstag = ps.where(product_id: tt["product_id"]).order("created_at DESC NULLS LAST").first
        if pstag != nil then
          pstag.update(arriving_qty: tt["check_quantity"].to_i)
        end
      end

      logger.debug("-------------------------------------------")
      headers.each_with_index do |(key, value), index|
        @sheet.add_cell(0, 5 + index, value)
      end

      @sheet.add_cell(0, 10, "発注ケース数")
      @sheet.add_cell(0, 11, "発注総バラ数")
      @sheet.add_cell(0, 12, "発注先")

      mstocks = MaterialStock.where(user: user)

      tag.each_with_index do |temp, row|
        headers.each_with_index do |(key, value), col|
          @sheet.add_cell(1 + row, 5 + col, temp[key.to_s])
        end

        #不足分がある場合に入庫予定登録
        if temp["substract_quantity"] < 0 then
          logger.debug("****************************")
          result = MaterialStock.calc_order_num(user, temp["material_id"], temp["substract_quantity"].abs)
          order_num = result[0]
          total = result[1]
          supplier = result[2]
          @sheet.add_cell(1 + row, 10, order_num)
          @sheet.add_cell(1 + row, 11, total)
          @sheet.add_cell(1 + row, 12, supplier)
          MaterialStock.stock_update(user, temp["material_id"], "入庫予定", nil, order_num, 0, 0)
        end

        #登録分を出庫予定登録
        if temp["check_quantity"] > 0 then
          result = MaterialStock.calc_ship(user, temp["material_id"], temp["check_quantity"])
          MaterialStock.stock_update(user, temp["material_id"], "出庫予定", nil, result[0], result[1], result[2])
        end

      end

      data = @workbook.stream.read
      timestamp = Time.new.strftime("%Y%m%d%H%M")
      send_data data, filename: "必要素材集計_" + timestamp + ".xlsx", type: "application/xlsx", disposition: "attachment"

    end
  end


  def check_template
    user = current_user.email
    respond_to do |format|
      format.html
      format.xlsx do
        @workbook = RubyXL::Workbook.new
        @sheet = @workbook.first

        headers = {
          product_id: "商品コード",
          check_quantity: "必要数量",
          name: "商品名"
        }

        headers.each_with_index do |(key, value), index|
          @sheet.add_cell(0, index, value)
        end

        @sheet.add_cell(0, 3, "売れ行き(14日間)")

        @products = Product.where(user: user)
        recipes = Recipe.where(user: user)
        row = 0

        @reports = Report.where(user: user)

        @products.each_with_index do |tproduct, index|
          if recipes.where(product_id: tproduct.product_id).count > 0 then
            @sheet.add_cell(1 + row, 0, tproduct.product_id)
            @sheet.add_cell(1 + row, 1, 0)
            @sheet.add_cell(1 + row, 2, tproduct.name)

            ts = @reports.where(product_id: tproduct.product_id).order("recorded_at DESC NULLS LAST").first
            if ts != nil then
              ts = ts.recorded_at
              buf = @reports.where(product_id: tproduct.product_id).where("recorded_at > ?", ts.ago(14.days))
              @sheet.add_cell(1 + row, 3, buf.average(:order_quantity).to_f.round(0))
            end

            row += 1
          end
        end
        timestamp = Time.new.strftime("%Y%m%d%H%M%S")
        data = @workbook.stream.read
        send_data data, filename: "素材数量確認用テンプレート_" + timestamp + ".xlsx", type: "application/xlsx", disposition: "attachment"
      end
    end
  end

  def pickup
    user = current_user.email
    if request.post? then
      data = params[:product_ship_data]
      if data != nil then
        ext = File.extname(data.path)
        if ext == ".xlsx" then
          workbook = RubyXL::Parser.parse(data.path)
          worksheet = workbook.first
          sheet_header = worksheet.sheet_data[0]
          logger.debug("====== HEADER CHECK =========")

          headers = {
            product_id: "商品コード",
            name: "商品名",
            check_quantity: "入庫予定数量"
          }
          inv_headers = headers.invert
          pstocks = ProductStock.where(user: user)

          header_check = true
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
            logger.debug("====== HEADER OK! =========")
          else
            logger.debug("====== HEADER NG =========")
            return
          end

          product_list = Array.new
          worksheet.each_with_index do |row, index|
            if index > 0 then
              logger.debug("====== ROW " + index.to_s  + " =========")
              input_row = Hash.new
              headers.each_with_index do |head, col|
                name = sheet_header[col].value
                key = inv_headers[name]
                if row[col] != nil then
                  value = row[col].value
                else
                  value = nil
                end
                input_row[key] = value
              end
              if input_row[:check_quantity].to_i > 0 then
                tg = pstocks.where(product_id: input_row[:product_id]).order("created_at DESC").first
                if tg != nil then
                  new_s = tg.arriving_qty.to_i - input_row[:check_quantity].to_i
                  if new_s < 0 then new_s = 0 end
                  tg.update(
                      arriving_qty: new_s
                  )
                end
                product_list << input_row
              end
            end
          end

          recipes = Recipe.where(user: user)
          required_materials = Hash.new
          db = Product.where(user: user)
          @workbook = RubyXL::Workbook.new
          @sheet = @workbook.first
          @sheet.sheet_name = "まとめ"

          product_list.each do |pitem|

            product_id = pitem[:product_id]
            pnum = pitem[:check_quantity].to_i
            rp = recipes.where(product_id: product_id)

            tsh = @workbook.add_worksheet(product_id)
            tsh.add_cell(0, 0, "商品コード")
            tsh.add_cell(0, 1, "商品名")
            tsh.add_cell(1, 0, product_id)
            tsh.add_cell(1, 1, db.find_by(product_id: product_id).name)

            tsh.add_cell(3, 0, "素材コード")
            tsh.add_cell(3, 1, "素材名")
            tsh.add_cell(3, 2, "必要総数量")
            trow = 0
            rp.each do |mat|
              tsh.add_cell(4 + trow, 0, mat.material_id)
              tsh.add_cell(4 + trow, 1, mat.material.name)
              tsh.add_cell(4 + trow, 2, mat.required_qty.to_i * pnum)
              trow += 1
              if required_materials.key?(mat.material_id) then
                required_materials[mat.material_id] = required_materials[mat.material_id].to_i + mat.required_qty.to_i * pnum
              else
                required_materials[mat.material_id] = mat.required_qty.to_i * pnum
              end
            end
          end


          theader = {
            material_id: "素材コード",
            name: "素材名",
            expire: "賞味期限",
            required_qty: "必要総数量",
            location_id: "ロケーション",
            checked: "チェック"
          }

          theader.each_with_index do |(key, value), index|
            @sheet.add_cell(0, index, value)
          end

          master = MaterialStock.where(user: user)
          row = 0
          required_materials.each_with_index do |(key, value), index|
            ms = master.where(material_id: key).where.not(expire: nil).order("expire ASC")
            req = value
            ms.each do |temp|
              if temp.current_total > 0 then
                if req <= temp.current_total then
                  input_total = req
                  @sheet.add_cell(1 + row , 0, key)
                  @sheet.add_cell(1 + row , 1, temp.material.name)
                  @sheet.add_cell(1 + row , 2, temp.expire.strftime("%Y/%m/%d"))
                  @sheet.add_cell(1 + row , 3, input_total)
                  @sheet.add_cell(1 + row , 4, temp.material.location_id)
                  @sheet.add_cell(1 + row , 5, nil)
                  row += 1
                  break
                else
                  input_total = temp.current_total
                  req = req - temp.current_total
                  @sheet.add_cell(1 + row , 0, key)
                  @sheet.add_cell(1 + row , 1, temp.material.name)
                  @sheet.add_cell(1 + row , 2, temp.expire.strftime("%Y/%m/%d"))
                  @sheet.add_cell(1 + row , 3, input_total)
                  @sheet.add_cell(1 + row , 4, temp.material.location_id)
                  @sheet.add_cell(1 + row , 5, nil)
                  row += 1
                end
              end
            end
          end
          timestamp = Time.new.strftime("%Y%m%d%H%M%S")
          data = @workbook.stream.read
          send_data data, filename: "素材出庫確認用リスト_" + timestamp + ".xlsx", type: "application/xlsx", disposition: "attachment"

        end
      end
    else
      respond_to do |format|
        format.html
        format.xlsx do
          @workbook = RubyXL::Workbook.new
          @sheet = @workbook.first

          headers = {
            product_id: "商品コード",
            name: "商品名",
            check_quantity: "入庫予定数量"
          }

          headers.each_with_index do |(key, value), index|
            @sheet.add_cell(0, index, value)
          end

          @products = Product.where(user: user)
          recipes = Recipe.where(user: user)
          row = 0
          @products.each_with_index do |tproduct, index|
            if recipes.where(product_id: tproduct.product_id).count > 0 then
              @sheet.add_cell(1 + row, 0, tproduct.product_id)
              @sheet.add_cell(1 + row, 1, tproduct.name)
              @sheet.add_cell(1 + row, 2, 0)
              row += 1
            end
          end
          timestamp = Time.new.strftime("%Y%m%d%H%M%S")
          data = @workbook.stream.read
          send_data data, filename: "商品入庫予定確認用テンプレート_" + timestamp + ".xlsx", type: "application/xlsx", disposition: "attachment"
        end
      end
    end
  end

  def destroy
    @login_user = current_user
    user = current_user.email
    @user = User.find(current_user.id)
    if request.post? then
      logger.debug("========")
      password = params[:user][:current_password]
      commit = params[:commit]
      if @user.valid_password?(params[:user][:current_password]) then
        if commit == "商品マスタ削除" then
          Product.where(user: user).delete_all
        elsif commit == "素材マスタ削除" then
          Material.where(user: user).delete_all
        elsif commit == "商品在庫削除" then
          ProductStock.where(user: user).delete_all
        elsif commit == "素材在庫削除" then
          MaterialStock.where(user: user).delete_all
        elsif commit == "店舗情報削除" then
          Seller.where(user: user).delete_all
        elsif commit == "仕入れ先情報削除" then
          Supplier.where(user: user).delete_all
        end
      end

    end
  end

end
