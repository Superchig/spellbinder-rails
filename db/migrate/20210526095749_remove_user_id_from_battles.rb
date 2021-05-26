class RemoveUserIdFromBattles < ActiveRecord::Migration[6.1]
  def change
    remove_index :battles, :user_id
    remove_column :battles, :user_id, :integer
  end
end
