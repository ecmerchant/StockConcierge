module Constants
  ## Constants::xx でアクセス
  CONV_PRODUCT = {
    product_id: "ASIN",
    fba_sku: "SKU(FBA)",
    self_sku: "SKU(自社配送)",
    name: "商品名",
    price: "販売価格",
    fee: "アマゾン手数料",
    cost: "原価",
    expense: "経費",
    profit: "利益額",
    seller_id: "店舗"
  }

  CONV_MATERIAL = {
    material_id: "素材コード",
    name: "素材名",
    category_id: "カテゴリー",
    cost: "仕入単価",
    expense: "経費",
    supplier_id: "仕入れ先名",
    qty_per_package: "1パッケージあたりのバラ数",
    package_per_case: "1ケースあたりのパッケージ数",
    location_id: "ロケーション",
  }

  CONV_MSTOCK = {
    material_id: "素材コード",
    name: "素材名",
    updated_at: "更新日",
    action: "種別",
    input_case: "登録ケース数",
    input_package: "登録パッケージ数",
    input_qty: "登録バラ数",
    current_case: "現在庫（ケース）",
    current_package: "現在庫（パッケージ）",
    current_qty: "現在庫（バラ）",
    current_total: "現在庫（総数）",
    arriving_case: "入庫予定（ケース）",
    arriving_package: "入庫予定（パッケージ）",
    arriving_qty: "入庫予定（バラ）",
    arriving_total: "入庫予定（総数）",
    shipping_case: "出庫予定（ケース）",
    shipping_package: "出庫予定（パッケージ）",
    shipping_qty: "出庫予定（バラ）",
    shipping_total: "出庫予定（総数）"
  }

  CONV_MSTOCK_D = {
    material_id: "素材コード",
    name: "素材名",
    expire: "賞味期限",
    current_case: "現在庫（ケース）",
    current_package: "現在庫（パッケージ）",
    current_qty: "現在庫（バラ）",
    current_total: "現在庫（総数）",
    updated_at: "更新日"
  }


  CONV_RECIPE = {
    product_id: "ASIN",
    material_id: "素材コード",
    name: "素材名",
    required_qty: "数量"
  }

  CONV_PSTOCK = {
    product_id: "商品コード",
    name: "商品名",
    recorded_at: "更新日",
    self_qty: "自己在庫数",
    fba_qty: "FBA在庫数",
    total_qty: "合計在庫数",
    arriving_qty: "入庫予定在庫"
  }

  CONV_SELLER = {
    name: "店舗名",
    seller_id: "セラーID",
    aws_access_key_id: "AWSアクセスキー",
    secret_key_id: "秘密キー"
  }

  CONV_SUPPLIER = {
    supplier_id: "店舗ID",
    name: "店舗名",
    email: "メールアドレス",
    phone: "電話番号",
    fax: "FAX",
    address: "住所",
    url: "URL",
    memo: "メモ"
  }

  CONV_REPORT = {
    product_id: "商品コード",
    recorded_at: "データ取得日",
    session: "セッション",
    session_rate: "セッションのパーセンテージ",
    page_view: "ページビュー",
    page_view_rate: "ページビュー率",
    cart_box_rate: "カートボックス獲得率",
    order_quantity: "注文された商品点数",
    unit_session_rate: "ユニットセッション率",
    sale: "注文商品売上",
    total: "注文品目総数",
    impression: "インプレッション",
    click: "クリック",
    click_through_rate: "クリックスルー率 (CTR)",
    click_per_cost: "平均クリック単価 (CPC)",
    cost: "広告費",
    total_sale: "広告がクリックされてから7日間の総売上高",
    adv_cost_of_sale: "売上高に占める広告費の割合 （ACoS)",
    return_on_adv_spend: "広告費用対効果 (RoAS)"
  }


end
