class ChangeBattleStreamsToBattleStates < ActiveRecord::Migration[6.1]
  def change
    rename_table :battle_streams, :battle_states
  end
end
