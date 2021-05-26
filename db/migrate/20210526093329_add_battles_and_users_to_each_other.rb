class AddBattlesAndUsersToEachOther < ActiveRecord::Migration[6.1]
  def change
    create_table :battles_users do |t|
      t.belongs_to :battle
      t.belongs_to :user

      t.timestamps
    end
  end
end
