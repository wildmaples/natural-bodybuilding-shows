require "test_helper"

class FullScrapeFlowTest < ActionDispatch::IntegrationTest
  test "scraping populates database and events display on homepage" do
    # Start with empty database
    Event.delete_all
    assert_equal 0, Event.count

    # Run scrapers against live websites
    results = ScraperManager.new.scrape_all

    # Verify at least one scraper succeeded
    assert results.any? { |r| r[:success] }, "At least one scraper should succeed"

    # Skip further checks if no events were found (both sites might be down)
    total_events = results.sum { |r| r[:count] }
    skip "No events were scraped - websites may be unavailable" if total_events == 0

    # Verify events were created
    assert Event.count > 0, "Scraping should create events"

    # Verify homepage displays events
    get root_path
    assert_response :success

    # Check that at least one event appears on the page
    Event.upcoming.limit(3).each do |event|
      assert_match event.name, response.body, "Event '#{event.name}' should appear on homepage"
    end
  end

  test "API returns scraped events" do
    # Ensure we have some events
    Event.delete_all
    Event.create!(name: "Integration Test Event", date: Date.tomorrow, federation: "OCB", location: "Test City")

    get api_v1_events_path
    assert_response :success

    json = JSON.parse(response.body)
    assert json.any?, "API should return events"
    assert_equal "Integration Test Event", json.first["name"]
  end

  test "health endpoint reflects current state" do
    Event.delete_all

    get health_path
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal "ok", json["status"]
    assert_equal 0, json["event_count"]

    # Add an event
    Event.create!(name: "Health Test Event", federation: "WNBF", date: Date.today)

    get health_path
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal 1, json["event_count"]
  end

  test "scraper manager tracks data freshness correctly" do
    Event.delete_all
    manager = ScraperManager.new

    # No events = no data available
    assert_equal "No data available", manager.data_freshness

    # Add a fresh event
    Event.create!(name: "Fresh Event", federation: "OCB", date: Date.tomorrow)

    # Freshness should now be recent
    freshness = manager.data_freshness
    assert freshness.include?("hour") || freshness.include?("Less than"), "Fresh event should show recent update"
  end
end
