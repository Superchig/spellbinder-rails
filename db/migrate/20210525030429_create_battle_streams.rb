class CreateBattleStreams < ActiveRecord::Migration[6.1]
  def change
    create_table :battle_streams do |t|
      t.string :left_hand
      t.string :right_hand

      t.timestamps
    end
  end
end
