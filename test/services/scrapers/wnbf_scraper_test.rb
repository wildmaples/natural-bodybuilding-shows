require "test_helper"

class WnbfScraperTest < ActiveSupport::TestCase
  test "scrapes real WNBF events from live website" do
    scraper = Scrapers::WnbfScraper.new
    events = scraper.scrape

    assert events.any?, "Should find at least one WNBF event"

    event = events.first
    assert event[:name].present?, "Event should have a name"
    assert_equal "WNBF", event[:federation], "Federation should be WNBF"
  end

  test "scrape_and_save persists events to database" do
    Event.delete_all
    scraper = Scrapers::WnbfScraper.new
    events = scraper.scrape_and_save

    skip "WNBF website may be returning no events" if events.empty?

    assert Event.where(federation: "WNBF").any?, "Should have WNBF events in database"
  end

  test "events have expected structure" do
    scraper = Scrapers::WnbfScraper.new
    events = scraper.scrape

    skip "No WNBF events found - website may be down" if events.empty?

    event = events.first
    assert event.key?(:name), "Event should have name key"
    assert event.key?(:date), "Event should have date key"
    assert event.key?(:location), "Event should have location key"
    assert event.key?(:url), "Event should have url key"
    assert event.key?(:federation), "Event should have federation key"
  end

  test "event names are cleaned properly" do
    scraper = Scrapers::WnbfScraper.new
    events = scraper.scrape

    skip "No WNBF events found - website may be down" if events.empty?

    events.each do |event|
      assert event[:name].length >= 5, "Event name should be at least 5 chars: #{event[:name]}"
      refute event[:name].match?(/^\d+\s/), "Event name should not start with numbers: #{event[:name]}"
    end
  end
end
