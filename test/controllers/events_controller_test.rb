require "test_helper"

class EventsControllerTest < ActionDispatch::IntegrationTest
  setup do
    Event.delete_all
    @upcoming_ocb = Event.create!(name: "Test Show", date: Date.tomorrow, federation: "OCB", location: "New York, NY")
    @upcoming_wnbf = Event.create!(name: "WNBF Classic", date: 1.week.from_now, federation: "WNBF", location: "Los Angeles, CA")
    @past_event = Event.create!(name: "Past Show", date: Date.yesterday, federation: "WNBF", location: "Chicago, IL")
  end

  test "index shows upcoming events" do
    get root_path
    assert_response :success
    assert_match "Test Show", response.body
    assert_match "WNBF Classic", response.body
  end

  test "index shows past events" do
    get root_path
    assert_response :success
    assert_match "Past Show", response.body
  end

  test "filters by federation" do
    get root_path, params: { federation: "OCB" }
    assert_response :success
    assert_match "Test Show", response.body
    assert_no_match(/WNBF Classic/, response.body)
  end

  test "filters by location" do
    get root_path, params: { location: "New York" }
    assert_response :success
    assert_match "Test Show", response.body
    assert_no_match(/Los Angeles/, response.body)
  end

  test "filters by name" do
    get root_path, params: { name: "Classic" }
    assert_response :success
    assert_match "WNBF Classic", response.body
    assert_no_match(/Test Show/, response.body)
  end

  test "shows event counts" do
    get root_path
    assert_response :success
    assert_match "2 upcoming", response.body
    assert_match "1 past", response.body
  end

  test "shows empty state when no events" do
    Event.delete_all
    get root_path
    assert_response :success
    assert_match "No upcoming shows found", response.body
  end
end
