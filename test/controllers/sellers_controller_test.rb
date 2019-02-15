require 'test_helper'

class SellersControllerTest < ActionDispatch::IntegrationTest
  test "should get edit" do
    get sellers_edit_url
    assert_response :success
  end

end
