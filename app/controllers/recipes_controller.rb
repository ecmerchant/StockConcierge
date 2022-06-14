class RecipesController < ApplicationController
  require 'rubyXL'

  before_action :authenticate_user!

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url, :alert => exception.message
  end

  def edit
    @login_user = current_user
    user = current_user.email
    @product_id = params[:product_id]
    if @product_id != nil then
      @recipes = Recipe.where(user: user, product_id: @product_id)
      product = Product.where(user: user).find_by(product_id: @product_id)
      @material_num = @recipes.sum(:required_qty)
      @cost = product.cost
      if @cost == nil then
        target = Product.find_by(user: user, product_id: @product_id)
        recipes = Recipe.where(user: user, product_id: @product_id )
        @cost = 0
        recipes.each do |recipe|
          @cost = @cost + recipe.material.cost * recipe.required_qty
        end
        target.update(
          cost: @cost,
          profit: (target.price - @cost).round(0)
        )
      end
      @name = product.name
    else
      @recipes = Recipe.where(user: user)
      @name = "-"
    end

    @headers = Constants::CONV_RECIPE
    inv_headers = @headers.invert
    if request.post? then
      data = params[:recipe_data]
      if data != nil then
        ext = File.extname(data.path)
        if ext == ".xlsx" then
          workbook = RubyXL::Parser.parse(data.path)
          worksheet = workbook.worksheets[0]
          sheet_header = worksheet.sheet_data[0]
          logger.debug("====== HEADER CHECK =========")
          product_id = worksheet[1][0].value
          user = current_user.email
          if product_id == nil then return end
          Recipe.where(user: user, product_id: product_id).delete_all
          cost = 0.0
          worksheet.each_with_index do |row, index|
            if index > 3 then
              logger.debug("====== ROW " + index.to_s  + " =========")
              input_row = Hash.new
              input_row[:product_id] = product_id
              input_row[:material_id] = row[0].value
              input_row[:required_qty] = row[4].value
              input_row[:user] = user

              if input_row[:required_qty].to_i > 0 then
                Recipe.find_or_create_by(input_row)
              end
              input_row = nil
            end
          end
          target = Product.find_by(user: user, product_id: product_id)
          recipes = Recipe.where(user: user, product_id: product_id )
          cost = 0
          recipes.each do |recipe|
            cost = cost + recipe.material.cost * recipe.required_qty
          end
          target.update(
            cost: cost,
            profit: (target.price - cost).round(0)
          )
        end
      end
    end
  end

  def delete
    @login_user = current_user
    user = current_user.email
    @recipes = Recipe.where(user: user)
    @headers = Constants::CONV_RECIPE
    inv_headers = @headers.invert
    if request.post? then
      data = params[:supplier_delete_data]
      if data != nil then
        ext = File.extname(data.path)
        if ext == ".xlsx" then
          workbook = RubyXL::Parser.parse(data.path)
          worksheet = workbook.worksheets[0]
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
                tag = @recipes.find_by(material_id: code)
                if tag != nil then
                  tag.delete
                end
              end
            end
          end
        end
      end
    end
    redirect_to recipes_edit_path
  end

  def template
    respond_to do |format|
      format.html
      format.xlsx do
        @workbook = RubyXL::Workbook.new
        @sheet = @workbook.worksheets[0]
        user = current_user.email
        headers = Constants::CONV_RECIPE

        product_id = params[:product_id]

        title = ""
        if product_id != nil then
          recipe = Recipe.where(user: user, product_id: product_id)
          title = Product.find_by(user: user, product_id: product_id)
          if title != nil then title = title.name end
          logger.debug("----------------")
          logger.debug(title)
        end

        @sheet.add_cell(0, 0, "登録ASIN")
        @sheet.add_cell(1, 0, product_id)
        @sheet.add_cell(0, 1, "商品名")
        @sheet.add_cell(1, 1, title)
        @sheet.add_cell(0, 2, "合計素材点数")
        @sheet.add_cell(1, 2, '', '=SUM(E5:E48576)')
        @sheet.add_cell(0, 3, "合計原価")
        @sheet.add_cell(1, 3, '', '=SUM(F5:F48576)')

        headers = {
          code: "素材コード",
          name: "素材名",
          category: "カテゴリー",
          cost: "仕入単価",
          quantity: "必要数量",
          sum: "コスト"
        }

        headers.each_with_index do |(key, value), index|
          @sheet.add_cell(3, index, value)
        end

        materials = Material.where(user: user).order("category_id ASC")

        materials.each_with_index do |material, index|
          @sheet.add_cell(4 + index, 0, material.material_id)
          @sheet.add_cell(4 + index, 1, material.name)
          @sheet.add_cell(4 + index, 2, material.category.name)
          @sheet.add_cell(4 + index, 3, material.cost)

          if product_id != nil then
            tag = recipe.find_by(material_id: material.material_id)
            if tag != nil then
              quantity = tag.required_qty
            else
              quantity = 0
            end
            @sheet.add_cell(4 + index, 4, quantity)
          else
            @sheet.add_cell(4 + index, 4, 0)
          end

          formula = "=D" + (5 + index).to_s + "*E" + (5+ index).to_s
          @sheet.add_cell(4 + index, 5,'', formula)
        end

        data = @workbook.stream.read
        timestamp = Time.new.strftime("%Y%m%d%H%M%S")
        if product_id != nil then
          send_data data, filename: "レシピ登録用_" + product_id.to_s + "_" + timestamp + ".xlsx", type: "application/xlsx", disposition: "attachment"
        else
          send_data data, filename: "レシピ登録用_" + timestamp + ".xlsx", type: "application/xlsx", disposition: "attachment"
        end
      end
    end
  end

  def output
    respond_to do |format|
      format.html
      format.xlsx do
        @workbook = RubyXL::Workbook.new
        @sheet = @workbook.worksheets[0]
        user = current_user.email
        headers = Constants::CONV_RECIPE

        headers.each_with_index do |(key, value), index|
          @sheet.add_cell(0, index, value)
        end

        recipes = Recipe.where(user: user)

        recipes.each_with_index do |material, row|
          headers.each_with_index do |(key, value), col|
            @sheet.add_cell(1 + row, col, material[key])
          end
        end

        data = @workbook.stream.read
        timestamp = Time.new.strftime("%Y%m%d%H%M%S")
        send_data data, filename: "レシピ情報_" + timestamp + ".xlsx", type: "application/xlsx", disposition: "attachment"

      end
    end
  end
end
