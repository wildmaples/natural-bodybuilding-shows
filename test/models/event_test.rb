require "test_helper"

class EventTest < ActiveSupport::TestCase
  test "valid event with all required attributes" do
    event = Event.new(name: "Test Show", federation: "OCB")
    assert event.valid?
  end

  test "requires name" do
    event = Event.new(federation: "OCB")
    assert_not event.valid?
    assert_includes event.errors[:name], "can't be blank"
  end

  test "requires federation" do
    event = Event.new(name: "Test Show")
    assert_not event.valid?
    assert_includes event.errors[:federation], "can't be blank"
  end

  test "federation must be OCB or WNBF" do
    event = Event.new(name: "Test Show", federation: "INVALID")
    assert_not event.valid?
    assert_includes event.errors[:federation], "is not included in the list"

    event.federation = "OCB"
    assert event.valid?

    event.federation = "WNBF"
    assert event.valid?
  end

  test "upcoming scope returns future events and events with nil dates" do
    past_event = Event.create!(name: "Past Show", date: Date.yesterday, federation: "OCB")
    future_event = Event.create!(name: "Future Show", date: Date.tomorrow, federation: "OCB")
    tba_event = Event.create!(name: "TBA Show", date: nil, federation: "OCB")

    upcoming = Event.upcoming

    assert_includes upcoming, future_event
    assert_includes upcoming, tba_event
    assert_not_includes upcoming, past_event
  end

  test "past scope returns only past events" do
    past_event = Event.create!(name: "Past Show", date: Date.yesterday, federation: "OCB")
    future_event = Event.create!(name: "Future Show", date: Date.tomorrow, federation: "OCB")
    tba_event = Event.create!(name: "TBA Show", date: nil, federation: "WNBF")

    past = Event.past

    assert_includes past, past_event
    assert_not_includes past, future_event
    assert_not_includes past, tba_event
  end

  test "upcoming scope orders by date ascending" do
    Event.delete_all
    event1 = Event.create!(name: "Later Show", date: 1.week.from_now, federation: "OCB")
    event2 = Event.create!(name: "Soon Show", date: Date.tomorrow, federation: "OCB")

    upcoming = Event.upcoming.to_a

    assert_equal event2, upcoming.first
    assert_equal event1, upcoming.second
  end

  test "past scope orders by date descending" do
    Event.delete_all
    event1 = Event.create!(name: "Old Show", date: 2.weeks.ago, federation: "OCB")
    event2 = Event.create!(name: "Recent Show", date: Date.yesterday, federation: "OCB")

    past = Event.past.to_a

    assert_equal event2, past.first
    assert_equal event1, past.second
  end

  test "by_federation scope filters by federation" do
    ocb_event = Event.create!(name: "OCB Show", federation: "OCB", date: Date.tomorrow)
    wnbf_event = Event.create!(name: "WNBF Show", federation: "WNBF", date: Date.tomorrow)

    ocb_events = Event.by_federation("OCB")
    wnbf_events = Event.by_federation("WNBF")

    assert_includes ocb_events, ocb_event
    assert_not_includes ocb_events, wnbf_event

    assert_includes wnbf_events, wnbf_event
    assert_not_includes wnbf_events, ocb_event
  end

  test "by_federation scope returns all when nil" do
    ocb_event = Event.create!(name: "OCB Show", federation: "OCB", date: Date.tomorrow)
    wnbf_event = Event.create!(name: "WNBF Show", federation: "WNBF", date: Date.tomorrow)

    all_events = Event.by_federation(nil)

    assert_includes all_events, ocb_event
    assert_includes all_events, wnbf_event
  end

  test "prevents duplicate events with same name, date, and federation" do
    Event.create!(name: "Unique Show", date: Date.tomorrow, federation: "OCB")

    duplicate = Event.new(name: "Unique Show", date: Date.tomorrow, federation: "OCB")
    assert_raises(ActiveRecord::RecordNotUnique) { duplicate.save! }
  end

  test "allows same name on different dates" do
    Event.create!(name: "Annual Show", date: Date.new(2025, 6, 1), federation: "OCB")
    event2 = Event.create!(name: "Annual Show", date: Date.new(2025, 7, 1), federation: "OCB")

    assert event2.persisted?
  end

  test "allows same name in different federations" do
    Event.create!(name: "Pro Cup", date: Date.tomorrow, federation: "OCB")
    event2 = Event.create!(name: "Pro Cup", date: Date.tomorrow, federation: "WNBF")

    assert event2.persisted?
  end

  test "upcoming? returns true for future dates" do
    event = Event.new(date: Date.tomorrow)
    assert event.upcoming?
  end

  test "upcoming? returns true for nil dates" do
    event = Event.new(date: nil)
    assert event.upcoming?
  end

  test "upcoming? returns false for past dates" do
    event = Event.new(date: Date.yesterday)
    assert_not event.upcoming?
  end

  test "past? returns true for past dates" do
    event = Event.new(date: Date.yesterday)
    assert event.past?
  end

  test "past? returns false for future dates" do
    event = Event.new(date: Date.tomorrow)
    assert_not event.past?
  end

  test "past? returns false for nil dates" do
    event = Event.new(date: nil)
    assert_not event.past?
  end

  test "formatted_date returns TBA for nil dates" do
    event = Event.new(date: nil)
    assert_equal "TBA", event.formatted_date
  end

  test "formatted_date returns formatted string for valid dates" do
    event = Event.new(date: Date.new(2025, 6, 15))
    assert_equal "Jun 15, 2025", event.formatted_date
  end
end
