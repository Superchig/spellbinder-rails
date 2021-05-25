require "test_helper"

class BattleControllerTest < ActionDispatch::IntegrationTest
  test "should get search" do
    get battle_search_url
    assert_response :success
  end
end
