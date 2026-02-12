require "test_helper"

class OcbScraperTest < ActiveSupport::TestCase
  setup do
    @scraper = Scrapers::OcbScraper.new
  end

  # --- extract_event_date ---

  test "extract_event_date parses MM-DD-YYYY from page text" do
    html = build_html("<p>Event date: 02-14-2026</p>")
    assert_equal Date.new(2026, 2, 14), @scraper.send(:extract_event_date, html)
  end

  test "extract_event_date picks the first valid date" do
    html = build_html("<p>02-14-2026 and also 03-21-2026</p>")
    assert_equal Date.new(2026, 2, 14), @scraper.send(:extract_event_date, html)
  end

  test "extract_event_date ignores dates before 2025" do
    html = build_html("<p>Last updated 01-15-2020</p><p>Event: 11-14-2026</p>")
    assert_equal Date.new(2026, 11, 14), @scraper.send(:extract_event_date, html)
  end

  test "extract_event_date returns nil when no date found" do
    html = build_html("<p>No date here</p>")
    assert_nil @scraper.send(:extract_event_date, html)
  end

  test "extract_event_date skips invalid dates gracefully" do
    html = build_html("<p>Date: 13-40-2026 or maybe 03-15-2026</p>")
    assert_equal Date.new(2026, 3, 15), @scraper.send(:extract_event_date, html)
  end

  # --- extract_event_location ---

  test "extract_event_location finds text after Location heading" do
    html = build_html("<h4>Location</h4><p>Wilmington, North Carolina</p>")
    assert_equal "Wilmington, North Carolina", @scraper.send(:extract_event_location, html)
  end

  test "extract_event_location is case-insensitive on heading" do
    html = build_html("<h4>LOCATION</h4><p>Houston, Texas</p>")
    assert_equal "Houston, Texas", @scraper.send(:extract_event_location, html)
  end

  test "extract_event_location skips non-location h4 headings" do
    html = build_html(<<~HTML)
      <h4>Date</h4><p>02-14-2026</p>
      <h4>Location</h4><p>Bloomington, Minnesota</p>
      <h4>Time</h4><p>10:00am</p>
    HTML
    assert_equal "Bloomington, Minnesota", @scraper.send(:extract_event_location, html)
  end

  test "extract_event_location returns nil when no Location heading" do
    html = build_html("<h4>Date</h4><p>02-14-2026</p>")
    assert_nil @scraper.send(:extract_event_location, html)
  end

  test "extract_event_location returns nil when sibling is empty" do
    html = build_html("<h4>Location</h4><p></p>")
    assert_nil @scraper.send(:extract_event_location, html)
  end

  # --- extract_state ---

  test "extract_state converts full state name to abbreviation" do
    assert_equal "NC", @scraper.send(:extract_state, "Wilmington, North Carolina")
    assert_equal "MN", @scraper.send(:extract_state, "Bloomington, Minnesota")
    assert_equal "TX", @scraper.send(:extract_state, "Houston, Texas")
  end

  test "extract_state passes through two-letter abbreviations" do
    assert_equal "VA", @scraper.send(:extract_state, "Richmond, VA")
    assert_equal "NY", @scraper.send(:extract_state, "Albany, NY")
  end

  test "extract_state returns nil for blank input" do
    assert_nil @scraper.send(:extract_state, nil)
    assert_nil @scraper.send(:extract_state, "")
  end

  test "extract_state returns nil for unknown state" do
    assert_nil @scraper.send(:extract_state, "Toronto, Ontario")
  end

  # --- build_events_from_api ---

  test "build_events_from_api parses API entries" do
    entries = [
      { "title" => { "rendered" => "OCB Gains and Glory" }, "link" => "https://ocbonline.com/events/ocb-gains-and-glory/" }
    ]

    events = @scraper.send(:build_events_from_api, entries)

    assert_equal 1, events.length
    assert_equal "OCB Gains and Glory", events.first[:name]
    assert_equal "https://ocbonline.com/events/ocb-gains-and-glory/", events.first[:url]
    assert_equal "OCB", events.first[:federation]
    assert_nil events.first[:date]
  end

  test "build_events_from_api strips HTML entities from titles" do
    entries = [
      { "title" => { "rendered" => "OCB Body Sculpting Open *Pro Qualifier" }, "link" => "https://example.com" }
    ]

    events = @scraper.send(:build_events_from_api, entries)

    assert_equal "OCB Body Sculpting Open *Pro Qualifier", events.first[:name]
  end

  test "build_events_from_api strips actual HTML tags from titles" do
    entries = [
      { "title" => { "rendered" => "OCB <em>Special</em> Event" }, "link" => "https://example.com" }
    ]

    events = @scraper.send(:build_events_from_api, entries)

    assert_equal "OCB Special Event", events.first[:name]
  end

  test "build_events_from_api skips entries with short names" do
    entries = [
      { "title" => { "rendered" => "TBA" }, "link" => "https://example.com" },
      { "title" => { "rendered" => "OCB Real Event Name" }, "link" => "https://example.com" }
    ]

    events = @scraper.send(:build_events_from_api, entries)

    assert_equal 1, events.length
    assert_equal "OCB Real Event Name", events.first[:name]
  end

  test "build_events_from_api skips entries with nil titles" do
    entries = [
      { "title" => { "rendered" => nil }, "link" => "https://example.com" }
    ]

    events = @scraper.send(:build_events_from_api, entries)

    assert_empty events
  end

  # --- live site tests (skip in CI) ---

  test "scrapes real OCB events from live website" do
    skip "Skipping live website test in CI" if ENV["CI"]

    events = @scraper.scrape

    skip "OCB website may be in maintenance mode or returning no events" if events.empty?

    event = events.first
    assert event[:name].present?, "Event should have a name"
    assert_equal "OCB", event[:federation], "Federation should be OCB"
    assert event[:date].is_a?(Date) || event[:date].nil?, "Date should be a Date or nil"
  end

  test "events have expected structure" do
    skip "Skipping live website test in CI" if ENV["CI"]

    events = @scraper.scrape

    skip "No OCB events found - website may be down" if events.empty?

    event = events.first
    assert event.key?(:name), "Event should have name key"
    assert event.key?(:date), "Event should have date key"
    assert event.key?(:location), "Event should have location key"
    assert event.key?(:url), "Event should have url key"
    assert event.key?(:federation), "Event should have federation key"
  end

  private

  def build_html(body)
    Nokogiri::HTML("<html><body>#{body}</body></html>")
  end
end
