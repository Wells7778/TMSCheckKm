class AddStatusToTmsrecords < ActiveRecord::Migration[5.1]
  def change
    add_column :tmsrecords, :status, :string
  end
end
