class BattleController < ApplicationController
  before_action :correct_user, only: [:show]
  before_action :authenticate_user!

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
      battle_state = BattleState.create(left_hand: '', right_hand: '', health: 15, user_id: user.id,
                                        battle_id: battle.id, orders_left_gesture: '', orders_left_spell: '',
                                        orders_left_target: '', orders_right_gesture: '', orders_right_spell: '',
                                        orders_right_target: '', orders_finished: false)
    end

    respond_to do |format|
      format.html { redirect_to battles_path, notice: 'Battle successfully created.' }
    end
  end

  # PATCH/PUT (probably PATCH), handles new turn orders
  def update
    battle_id = params[:battle_id]

    current_state = Battle.find(battle_id).battle_states.find { |battle_state| battle_state.user_id == current_user.id }
    current_state.orders_left_gesture = params[:left_gesture]
    current_state.orders_left_spell = params[:left_spell]
    current_state.orders_left_target = params[:left_target]
    current_state.orders_right_gesture = params[:right_gesture]
    current_state.orders_right_spell = params[:right_spell]
    current_state.orders_right_target = params[:right_target]
    current_state.orders_finished = true
    current_state.save

    respond_to do |format|
      format.html { redirect_back(fallback_location: root_path) }
    end
  end

  # GET
  def show
    @battle = Battle.find(params[:battle_id])

    @targets = @battle.users.reject { |user| user == current_user }.map { |user| user.email }
    @targets << 'Nobody'
    @targets.prepend('')

    @ordered_states = @battle.battle_states.sort_by { |state| state.user.email }
    @current_state = @ordered_states.find { |battle_state| battle_state.user_id == current_user.id }
  end

  def correct_user
    battle = current_user.battles.find_by(id: params[:battle_id])
    redirect_to battles_path, notice: 'Not authorized to access this battle.' if battle.nil?
  end
end
