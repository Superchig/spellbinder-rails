class BattleController < ApplicationController
  before_action :correct_user, only: [:show]

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
      format.html { redirect_to battles_path, notice: "Battle successfully created." }
    end
  end

  # GET
  def show
    @battle = Battle.find(params[:battle_id])

    @targets = @battle.users.reject { |user| user == current_user }.map { |user| user.email }
    @targets << "Nobody"
    @targets.prepend("")
  end

  def correct_user
    battle = current_user.battles.find_by(id: params[:battle_id])
    redirect_to battles_path, notice: "Not authorized to access this battle." if battle.nil?
  end
end
