module InvitationHelper
  def find_first_opponent(invitation)
    remainder = invitation.users.reject { |user| user == current_user }
    remainder.first
  end
end
