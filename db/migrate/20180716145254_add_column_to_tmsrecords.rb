class AddColumnToTmsrecords < ActiveRecord::Migration[5.1]
  def change
    add_column :tmsrecords, :c_km, :integer
    add_column :tmsrecords, :diff_km, :integer
  end
end
