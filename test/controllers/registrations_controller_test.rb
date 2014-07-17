require 'test_helper'

class RegistrationsControllerTest < ActionController::TestCase

  test "get register route" do
    @request.env["devise.mapping"] = Devise.mappings[:user]

    get :new

    assert_response :success
    assert_select "title", "Create an Account"
    assert_select "h4", "Joining a group?", 'invitation code block is empty'
  end

  test "get register route with invitation code" do
    @request.env["devise.mapping"] = Devise.mappings[:user]

    get :new, :invite_code => 'ABCDEFG'

    assert_response :success
    assert_select "title", "Create an Account"
    assert_select "h4", "You've been invited join a group!", 'invitation code block appears'
    assert_select "strong.invite_code", "ABCDEFG", 'invitation code appears'
  end

end