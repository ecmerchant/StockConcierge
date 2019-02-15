require 'test_helper'

class MaterialsControllerTest < ActionDispatch::IntegrationTest
  test "should get edit" do
    get materials_edit_url
    assert_response :success
  end

end
