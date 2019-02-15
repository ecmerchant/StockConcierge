require 'test_helper'

class RecipesControllerTest < ActionDispatch::IntegrationTest
  test "should get edit" do
    get recipes_edit_url
    assert_response :success
  end

end
