class AddUniqueToModels < ActiveRecord::Migration[5.2]
  def up
    execute <<-SQL
      ALTER TABLE materials
        ADD CONSTRAINT for_upsert_materials UNIQUE ("user", "material_id");
      ALTER TABLE products
        ADD CONSTRAINT for_upsert_products UNIQUE ("user", "product_id");
    SQL
  end

  def down
    execute <<-SQL
      ALTER TABLE materials
        DROP CONSTRAINT for_upsert_materials;
      ALTER TABLE products
        DROP CONSTRAINT for_upsert_products;
      ALTER TABLE material_stocks
        DROP CONSTRAINT for_upsert_material_stocks;
    SQL
  end

end
