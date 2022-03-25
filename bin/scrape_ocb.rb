require 'uri'
require 'net/http'
require 'nokogiri'
require 'yaml/store'
require 'date'

url = "https://ocbonline.com/event_schedule.php"
uri = URI.parse(url)
response = Net::HTTP.get_response(uri)

return unless response.is_a?(Net::HTTPSuccess)

html = Nokogiri::HTML(response.body)
events = html.xpath("//td[@data-title]")

ocb_amateur_events = {}

events.each_slice(3) do |x, y, z|
  begin
    date = x.children.text
    location = y.children.text
    name = z.children[1].children.text
    url = z.children[1].attributes["href"].value
    # require 'byebug'; debugger

    ocb_amateur_events[name.strip] = {
      "date" => date.strip,
      "location" => location.strip,
      "url" => url.strip
    }
  rescue TypeError => e
    require 'byebug'; debugger
    puts "wtf"
  end
end

store = YAML::Store.new("ocb_amateur_events.yaml")
store.transaction do
  store["validated"] = false
  store["last_updated"] = Date.today
  store["events"] = ocb_amateur_events
end
