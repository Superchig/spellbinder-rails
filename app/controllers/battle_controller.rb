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
    battle.users.concat(invitation.users)
    invitation.destroy

    battle.users.each do |user|
      battle_state = BattleState.create(left_hand: "", right_hand: "", health: 15, user_id: user.id, battle_id: battle.id)
    end

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

    @ordered_states = @battle.battle_states.sort_by { |state| state.user.email }
  end

  def correct_user
    battle = current_user.battles.find_by(id: params[:battle_id])
    redirect_to battles_path, notice: "Not authorized to access this battle." if battle.nil?
  end
end
