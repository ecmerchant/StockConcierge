class MaterialStock < ApplicationRecord
  belongs_to :material, primary_key: 'material_id', optional: true

  def self.calc_ship(user, material_id, qty)
    temp = Material.find_by(user: user, material_id: material_id)
    ppc = temp.package_per_case
    qpp = temp.qty_per_package

    ship_case = qty.div(ppc * qpp)
    qty = qty - ship_case * (ppc * qpp)
    shipping_package = qty.div(qpp)
    qty = qty - shipping_package * (qpp)
    shipping_qty = qty

    return [ship_case, shipping_package, shipping_qty]

  end


  def self.calc_order_num(user, material_id, qty)
    temp = Material.find_by(user: user, material_id: material_id)
    lot = temp.package_per_case * temp.qty_per_package
    order_num = qty.fdiv(lot).ceil
    total = order_num * lot
    supplier = temp.supplier.name
    return [order_num, total, supplier]
  end


  def self.stock_update(user, material_id, action, expire, input_case, input_package, input_qty)

    tg = MaterialStock.create(user: user, material_id: material_id, expire: nil, action: action, input_case: input_case, input_package: input_package, input_qty: input_qty)
    ppc = tg.material.package_per_case
    qpp = tg.material.qty_per_package
    input_total = (input_case.to_i * ppc + input_package.to_i) * qpp + input_qty.to_i
    mstocks = MaterialStock.where(user: user, material_id: material_id).where.not(expire: nil)
    last_target = MaterialStock.where(user: user, material_id: material_id, expire: nil).order("created_at DESC NULLS LAST").second

    if last_target != nil then
      current_case = last_target.current_case.to_i
      current_package = last_target.current_package.to_i
      current_qty = last_target.current_qty.to_i
      current_total = last_target.current_total.to_i
      before_arriving_case = last_target.arriving_case.to_i
      before_arriving_package = last_target.arriving_package.to_i
      before_arriving_qty = last_target.arriving_qty.to_i
      before_arriving_total = last_target.arriving_total.to_i
      before_shipping_case = last_target.shipping_case.to_i
      before_shipping_package = last_target.shipping_package.to_i
      before_shipping_qty = last_target.shipping_qty.to_i
      before_shipping_total = last_target.shipping_total.to_i
    else
      current_case = 0
      current_package = 0
      current_qty = 0
      current_total = 0
      before_arriving_case = 0
      before_arriving_package = 0
      before_arriving_qty = 0
      before_arriving_total = 0
      before_shipping_case = 0
      before_shipping_package = 0
      before_shipping_qty = 0
      before_shipping_total = 0
    end


    if action == "入庫" then
      target = MaterialStock.find_or_create_by(user: user, material_id: material_id, expire: expire)

      if target != nil then

        before_case = target.current_case.to_i
        before_package = target.current_package.to_i
        before_qty = target.current_qty.to_i
        before_total = target.current_total.to_i

        target.update(
          current_case: before_case + input_case.to_i,
          current_package: before_package + input_package.to_i,
          current_qty: before_qty + input_qty.to_i,
          current_total: before_total + input_total,
        )
      end

      current_case = mstocks.sum(:current_case)
      current_package = mstocks.sum(:current_package)
      current_qty = mstocks.sum(:current_qty)
      current_total = mstocks.sum(:current_total)

      tg.update(
        current_case: current_case,
        current_package: current_package,
        current_qty: current_qty,
        current_total: current_total,
        arriving_case: plusify(before_arriving_case - input_case.to_i),
        arriving_package: plusify(before_arriving_package - input_package.to_i),
        arriving_qty: plusify(before_arriving_qty - input_qty.to_i),
        arriving_total: plusify(before_arriving_total - input_total),
        shipping_case: before_shipping_case,
        shipping_package: before_shipping_package,
        shipping_qty: before_shipping_qty,
        shipping_total: before_shipping_total
      )


    elsif action == '入庫予定' then

      current_case = mstocks.sum(:current_case)
      current_package = mstocks.sum(:current_package)
      current_qty = mstocks.sum(:current_qty)
      current_total = mstocks.sum(:current_total)

      tg.update(
        current_case: current_case,
        current_package: current_package,
        current_qty: current_qty,
        current_total: current_total,
        arriving_case: before_arriving_case + input_case.to_i,
        arriving_package: before_arriving_package + input_package.to_i,
        arriving_qty: before_arriving_qty + input_qty.to_i,
        arriving_total: before_arriving_total + input_total,
        shipping_case: before_shipping_case,
        shipping_package: before_shipping_package,
        shipping_qty: before_shipping_qty,
        shipping_total: before_shipping_total
      )

    elsif action == '出庫' then
      target = MaterialStock.find_or_create_by(user: user, material_id: material_id, expire: expire)
      if target != nil then
        before_case = target.current_case.to_i
        before_package = target.current_package.to_i
        before_qty = target.current_qty.to_i
        before_total = target.current_total.to_i

        new_total = before_total - input_total
        if new_total >= 0 then
          res = MaterialStock.calc_ship(user, material_id, new_total)

          target.update(
            current_case: res[0],
            current_package: res[1],
            current_qty: res[2],
            current_total: before_total - input_total,
          )
        end
      end

      current_case = mstocks.sum(:current_case)
      current_package = mstocks.sum(:current_package)
      current_qty = mstocks.sum(:current_qty)
      current_total = mstocks.sum(:current_total)

      if before_shipping_total > input_total then
        tg.update(
          current_case: current_case,
          current_package: current_package,
          current_qty: current_qty,
          current_total: current_total,
          arriving_case: before_arriving_case,
          arriving_package: before_arriving_package,
          arriving_qty: before_arriving_qty,
          arriving_total: before_arriving_total,
          shipping_case: plusify(before_shipping_case - input_case.to_i),
          shipping_package: plusify(before_shipping_package - input_package.to_i),
          shipping_qty: plusify(before_shipping_qty - input_qty.to_i),
          shipping_total: plusify(before_shipping_total - input_total)
        )
      else
        tg.update(
          current_case: current_case,
          current_package: current_package,
          current_qty: current_qty,
          current_total: current_total,
          arriving_case: before_arriving_case,
          arriving_package: before_arriving_package,
          arriving_qty: before_arriving_qty,
          arriving_total: before_arriving_total,
          shipping_case: 0,
          shipping_package: 0,
          shipping_qty: 0,
          shipping_total: 0
        )
      end
    elsif action == '出庫予定' then

      current_case = mstocks.sum(:current_case)
      current_package = mstocks.sum(:current_package)
      current_qty = mstocks.sum(:current_qty)
      current_total = mstocks.sum(:current_total)

      tg.update(
        current_case: current_case,
        current_package: current_package,
        current_qty: current_qty,
        current_total: current_total,
        arriving_case: before_arriving_case,
        arriving_package: before_arriving_package,
        arriving_qty: before_arriving_qty,
        arriving_total: before_arriving_total,
        shipping_case: before_shipping_case + input_case.to_i,
        shipping_package: before_shipping_package + input_package.to_i,
        shipping_qty: before_shipping_qty + input_qty.to_i,
        shipping_total: before_shipping_total + input_total
      )

    elsif action == '棚卸' then
      new_total = (input_case.to_i * ppc + input_package.to_i) * qpp + input_qty.to_i
      target = MaterialStock.find_or_create_by(user: user, material_id: material_id, expire: expire)
      target.update(
        action: action,
        input_case: input_case,
        input_package: input_package,
        input_qty: input_qty,
        current_case: input_case,
        current_package: input_package,
        current_qty: input_qty,
        current_total: input_total,
        arriving_case: before_arriving_case,
        arriving_package: before_arriving_package,
        arriving_qty: before_arriving_qty,
        arriving_total: before_arriving_total,
        shipping_case: before_shipping_case,
        shipping_package: before_shipping_package,
        shipping_qty: before_shipping_qty,
        shipping_total: before_shipping_total
      )

      current_case = mstocks.sum(:current_case)
      current_package = mstocks.sum(:current_package)
      current_qty = mstocks.sum(:current_qty)
      current_total = mstocks.sum(:current_total)

      tg.update(
        current_case: current_case,
        current_package: current_package,
        current_qty: current_qty,
        current_total: current_total,
        arriving_case: before_arriving_case,
        arriving_package: before_arriving_package,
        arriving_qty: before_arriving_qty,
        arriving_total: before_arriving_total,
        shipping_case: before_shipping_case,
        shipping_package: before_shipping_package,
        shipping_qty: before_shipping_qty,
        shipping_total: before_shipping_total
      )

    end
  end


  private
  def self.plusify(number)
    if number < 0 then
      res = 0
    else
      res = number
    end
    return res
  end

end
