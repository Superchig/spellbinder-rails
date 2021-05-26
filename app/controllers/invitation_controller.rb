class InvitationController < ApplicationController
  before_action :authenticate_user!

  def show
    @opponents = current_user.invitations.map do |inv| 
      remaining = inv.users.reject { |user| user == current_user }
      remaining.first
    end

    @invitations = current_user.invitations
  end

  def new
    @starter_user = User.find(params[:starter_id])
  end

  def create
    # TODO(Chris): See if we should use build?
    invitation = current_user.invitations.create
    starter_user = User.find(params[:starter_id])
    starter_user.invitations << invitation

    respond_to do |format|
      format.html { redirect_to root_path, notice: "Invitation successfully sent." }
    end
  end
end
