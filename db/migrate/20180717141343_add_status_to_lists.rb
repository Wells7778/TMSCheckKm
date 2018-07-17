class AddStatusToLists < ActiveRecord::Migration[5.1]
  def change
    add_column :lists, :status, :string, default: ""
  end
end
