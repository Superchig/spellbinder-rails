class CreateInvitationsUsers < ActiveRecord::Migration[6.1]
  def change
    create_table :invitations_users do |t|
      t.belongs_to :invitation
      t.belongs_to :user

      t.timestamps
    end
  end
end
