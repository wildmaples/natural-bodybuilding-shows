require "test_helper"

class Api::V1::EventsControllerTest < ActionDispatch::IntegrationTest
  setup do
    Event.delete_all
    @event = Event.create!(name: "API Test", date: Date.tomorrow, federation: "OCB", location: "New York, NY")
    Event.create!(name: "WNBF Show", date: 1.week.from_now, federation: "WNBF", location: "Los Angeles, CA")
    Event.create!(name: "Past Show", date: Date.yesterday, federation: "OCB")
  end

  test "returns JSON list of upcoming events" do
    get api_v1_events_path
    assert_response :success

    json = JSON.parse(response.body)
    assert json.is_a?(Array)
    assert_equal 2, json.length # Only upcoming events
  end

  test "filters by federation" do
    get api_v1_events_path, params: { federation: "OCB" }
    assert_response :success

    json = JSON.parse(response.body)
    assert json.all? { |e| e["federation"] == "OCB" }
    assert_equal 1, json.length
  end

  test "filters by location" do
    get api_v1_events_path, params: { location: "New York" }
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal 1, json.length
    assert_match "New York", json.first["location"]
  end

  test "returns single event" do
    get api_v1_event_path(@event)
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal "API Test", json["name"]
    assert_equal "OCB", json["federation"]
  end

  test "returns 404 for non-existent event" do
    get api_v1_event_path(id: 999999)
    assert_response :not_found

    json = JSON.parse(response.body)
    assert_equal "Event not found", json["error"]
  end

  test "returns expected fields" do
    get api_v1_events_path
    assert_response :success

    json = JSON.parse(response.body)
    event = json.first

    expected_fields = %w[id name date location state url federation]
    expected_fields.each do |field|
      assert event.key?(field), "Expected field '#{field}' in response"
    end
  end

  test "orders by date ascending" do
    get api_v1_events_path
    assert_response :success

    json = JSON.parse(response.body)
    dates = json.map { |e| Date.parse(e["date"]) }
    assert_equal dates.sort, dates
  end
end
