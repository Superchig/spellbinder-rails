class AddOrdersToBattleStates < ActiveRecord::Migration[6.1]
  def change
    add_column :battle_states, :orders_left_gesture, :text
    add_column :battle_states, :orders_left_spell, :string
    add_column :battle_states, :orders_left_target, :string
    add_column :battle_states, :orders_right_gesture, :string
    add_column :battle_states, :orders_right_spell, :string
    add_column :battle_states, :orders_right_target, :string

    add_column :battle_states, :orders_finished, :boolean
  end
end
