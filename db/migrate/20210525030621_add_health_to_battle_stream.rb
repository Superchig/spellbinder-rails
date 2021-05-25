class AddHealthToBattleStream < ActiveRecord::Migration[6.1]
  def change
    add_column :battle_streams, :health, :integer
  end
end
