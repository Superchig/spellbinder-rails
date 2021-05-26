class BattleController < ApplicationController
  def search
    @available_users = User.all.select do |user|
      user != current_user
    end
  end

  # POST
  def create
    battle = Battle.create
    invitation = Invitation.find(params[:invitation_id])
    invitation.users.each do |user|
      user.battles << battle
    end
    invitation.destroy

    respond_to do |format|
      format.html { redirect_to battle_show_path, notice: "Battle successfully created." }
    end
  end

  # GET
  def show
  end
end
