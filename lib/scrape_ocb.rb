require 'uri'
require 'net/http'
require 'nokogiri'
require 'yaml/store'
require 'date'
require './bin/utils'

url = "https://ocbonline.com/event_schedule.php"
uri = URI.parse(url)
response = Net::HTTP.get_response(uri)

return unless response.is_a?(Net::HTTPSuccess)

html = Nokogiri::HTML(response.body)
events = html.xpath("//td[@data-title]")

ocb_amateur_events = {}

# OCB site organizes their shows in
# a html table with 3 columns containing
# the date, location and name (with url)
events.each_slice(3) do |x, y, z|
  date = x.text
  location = y.text
  name = z.children[1].text
  url = z.children[1]["href"]

  ocb_amateur_events[name.strip] = {
    "date" => Utils.convert_date(date.strip),
    "location" => location.strip,
    "url" => url.strip
  }
end

date_today = Date.today
file = File.path("db/ocb_amateur_events_#{date_today.to_s}.yml")
Utils.store_as_yaml(file, ocb_amateur_events)
