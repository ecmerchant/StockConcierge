require 'test_helper'

class ProductStocksControllerTest < ActionDispatch::IntegrationTest
  test "should get edit" do
    get product_stocks_edit_url
    assert_response :success
  end

end
