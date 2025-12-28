require "test_helper"

class OcbScraperTest < ActiveSupport::TestCase
  test "scrapes real OCB events from live website" do
    scraper = Scrapers::OcbScraper.new
    events = scraper.scrape

    # Skip if website is in maintenance mode or returning no events
    skip "OCB website may be in maintenance mode or returning no events" if events.empty?

    event = events.first
    assert event[:name].present?, "Event should have a name"
    assert_equal "OCB", event[:federation], "Federation should be OCB"
    assert event[:date].is_a?(Date) || event[:date].nil?, "Date should be a Date or nil"
  end

  test "scrape_and_save persists events to database" do
    Event.delete_all
    scraper = Scrapers::OcbScraper.new
    events = scraper.scrape_and_save

    # Skip if website is in maintenance mode
    skip "OCB website may be in maintenance mode" if events.empty?

    assert Event.where(federation: "OCB").any?, "Should have OCB events in database"
  end

  test "events have expected structure" do
    scraper = Scrapers::OcbScraper.new
    events = scraper.scrape

    skip "No OCB events found - website may be down" if events.empty?

    event = events.first
    assert event.key?(:name), "Event should have name key"
    assert event.key?(:date), "Event should have date key"
    assert event.key?(:location), "Event should have location key"
    assert event.key?(:url), "Event should have url key"
    assert event.key?(:federation), "Event should have federation key"
  end

  test "event URLs are valid when present" do
    scraper = Scrapers::OcbScraper.new
    events = scraper.scrape

    skip "No OCB events found - website may be down" if events.empty?

    events_with_urls = events.select { |e| e[:url].present? }
    skip "No events with URLs found" if events_with_urls.empty?

    events_with_urls.first(3).each do |event|
      assert event[:url].start_with?("http"), "URL should start with http: #{event[:url]}"
    end
  end
end
