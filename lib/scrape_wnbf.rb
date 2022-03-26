require 'uri'
require 'net/http'
require 'nokogiri'
require 'yaml/store'
require 'date'
require './bin/utils'

# Try to correctly split raw label into [date, name, state]
def split(label)

  # Most common case
  date, name, state = label.split("–")

  # Assign a default :state value
  # because sometimes the raw data doesn't contain a state
  #  e.g. "November 3 – New York Pro"
  state = "TBA" if state.nil?

  # If name remains nil at this point it's
  # because the raw data is split on "-"
  #  e.g. September 24- Naturalmania WNBF Pro Universe-NY
  date, name, state = label.split("-") if name.nil?

  [date, name, state]
end

url = "https://www.worldnaturalbb.com/2022-inbf-wnbf-events/"
uri = URI.parse(url)
response = Net::HTTP.get_response(uri)

return unless response.is_a?(Net::HTTPSuccess)

html = Nokogiri::HTML(response.body)
events = html.xpath("//div[@class='menu-all-events-container']").at_xpath("//ul[@id='menu-all-events']").children.children

wnbf_events = {}
events.each do |event|
  # Get the two fields we need
  event_link = event.attributes["href"].value
  event_label = event.children.text

  # The event label contains date, event name and state
  date, name, state = split(event_label)

  begin
    wnbf_events[name.strip] = { "date" => Utils.convert_date(date.strip), "state" => state.strip, "url" => event_link }

  rescue NoMethodError
    warn("Missed event entry due to unexpected raw format.")
  end
end

date_today = Date.today
file = File.path("db/wnbf_events_#{date_today.to_s}.yml")
Utils.store_as_yaml(file, wnbf_events)
