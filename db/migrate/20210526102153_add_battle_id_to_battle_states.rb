class AddBattleIdToBattleStates < ActiveRecord::Migration[6.1]
  def change
    add_column :battle_states, :battle_id, :integer
    add_index :battle_states, [:battle_id], :name => 'index_battle_states_on_battle_id'
  end
end
