class CreateTmsrecords < ActiveRecord::Migration[5.1]
  def change
    create_table :tmsrecords do |t|
      t.string  :number
      t.string  :post_code
      t.string  :dest
      t.integer :driver_km
      t.integer :list_id

      t.timestamps
    end
  end
end
