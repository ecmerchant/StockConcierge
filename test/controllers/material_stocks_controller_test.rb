require 'test_helper'

class MaterialStocksControllerTest < ActionDispatch::IntegrationTest
  test "should get edit" do
    get material_stocks_edit_url
    assert_response :success
  end

end
