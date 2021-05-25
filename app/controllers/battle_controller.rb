class BattleController < ApplicationController
  def search
    @users = User.all
  end
end
