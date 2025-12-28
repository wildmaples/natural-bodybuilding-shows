require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "about page renders" do
    get about_path
    assert_response :success
    assert_match "About natty.show", response.body
    assert_match "WNBF", response.body
    assert_match "OCB", response.body
  end

  test "health endpoint returns JSON" do
    Event.create!(name: "Test Event", federation: "OCB", date: Date.today)

    get health_path
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal "ok", json["status"]
    assert json.key?("event_count")
    assert json.key?("data_stale")
  end

  test "health endpoint works with no events" do
    Event.delete_all
    get health_path
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal "ok", json["status"]
    assert_equal 0, json["event_count"]
  end
end
