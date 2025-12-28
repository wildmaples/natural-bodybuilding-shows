require "application_system_test_case"

class EventsTest < ApplicationSystemTestCase
  setup do
    Event.delete_all
    Event.create!(name: "Naturalmania", date: 1.week.from_now, federation: "OCB", location: "Columbus, OH")
    Event.create!(name: "Pro Universe", date: 2.weeks.from_now, federation: "WNBF", location: "Teaneck, NJ")
    Event.create!(name: "Past Championship", date: 1.week.ago, federation: "OCB", location: "Miami, FL")
  end

  test "visiting the home page shows events" do
    visit root_path
    assert_selector "h1", text: "natty.show"
    assert_text "Naturalmania"
    assert_text "Pro Universe"
  end

  test "filtering by federation" do
    visit root_path
    select "OCB", from: "Federation"
    click_button "Search"

    assert_text "Naturalmania"
    assert_no_text "Pro Universe"
  end

  test "filtering by name" do
    visit root_path
    fill_in "Show Name", with: "Universe"
    click_button "Search"

    assert_text "Pro Universe"
    assert_no_text "Naturalmania"
  end

  test "filtering by location" do
    visit root_path
    fill_in "Location", with: "Columbus"
    click_button "Search"

    assert_text "Naturalmania"
    assert_no_text "Teaneck"
  end

  test "switching tabs shows past events" do
    visit root_path
    click_on "Past Shows"

    assert_text "Past Championship"
  end

  test "clear button resets filters" do
    visit root_path
    fill_in "Show Name", with: "Universe"
    click_button "Search"

    assert_text "Pro Universe"
    assert_no_text "Naturalmania"

    click_link "Clear"

    assert_text "Pro Universe"
    assert_text "Naturalmania"
  end

  test "event links work" do
    Event.create!(name: "Link Test", date: Date.tomorrow, federation: "WNBF", url: "https://example.com/event")
    visit root_path

    assert_selector "a[href='https://example.com/event']", text: "Link Test"
  end

  test "about page is accessible" do
    visit root_path
    click_link "About"

    assert_text "About natty.show"
    assert_text "World Natural Bodybuilding Federation"
    assert_text "Organization of Competitive Bodybuilders"
  end
end
