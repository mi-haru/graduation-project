class RenameNameToNicknameInUsers < ActiveRecord::Migration[8.1]
  def change
    rename_column :users, :name, :nickname
  end
end
