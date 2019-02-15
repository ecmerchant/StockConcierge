require 'test_helper'

class ReportsControllerTest < ActionDispatch::IntegrationTest
  test "should get edit" do
    get reports_edit_url
    assert_response :success
  end

end
