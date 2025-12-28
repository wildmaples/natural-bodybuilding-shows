module Scrapers
  class WnbfScraper < BaseScraper
    BASE_URL = "https://worldnaturalbb.com/usa-events/".freeze
    FEDERATION = "WNBF".freeze

    def scrape
      log_info("Starting scrape from #{BASE_URL}")

      html = fetch_page(BASE_URL)
      return [] unless html

      events = parse_events(html)
      log_info("Found #{events.count} events")
      events
    end

    private

    def parse_events(html)
      events = []
      # Events are in list items with fr-timeline-charlie__list-item class
      event_containers = html.css(".fr-timeline-charlie__list-item")

      log_info("Found #{event_containers.count} event containers on page")

      event_containers.each do |container|
        event_data = parse_event_container(container)
        events << event_data if event_data
      end

      events
    end

    def parse_event_container(container)
      # Find the title link within the heading
      title_link = container.css(".fr-timeline-charlie__heading a").first
      title_link ||= container.css("h2 a").first
      return nil unless title_link

      name = title_link.text.strip
      url = title_link["href"]

      return nil if name.empty? || name.length < 5

      # Extract date from datetime element
      datetime_element = container.css("time.event__start-date").first
      date = datetime_element ? extract_date_from_datetime(datetime_element) : nil

      # Fetch location from individual event page
      location = fetch_event_location(url)

      # Clean up the name
      name = clean_event_name(name)
      return nil if name.length < 5

      {
        name: name,
        date: date,
        location: location,
        state: extract_state(location),
        url: url || "",
        federation: FEDERATION
      }
    rescue StandardError => e
      log_warn("Skipping event due to parsing error: #{e.message}")
      nil
    end

    def fetch_event_location(event_url)
      return nil unless event_url

      html = fetch_page(event_url)
      return nil unless html

      # Look for location information
      location_element = html.css(".main-event__location-text").first
      if location_element
        location = location_element.text.strip
        return location unless location.empty?
      end

      # Fallback: look for any element with location in class name
      location_elements = html.css('[class*="location"]')
      location_elements.each do |el|
        location = el.text.strip
        return location if location.length.positive? && location.length < 100
      end

      nil
    rescue StandardError => e
      log_warn("Failed to fetch location for event: #{e.message}")
      nil
    end

    def extract_date_from_datetime(datetime_element)
      # First try to extract date from text content
      text = datetime_element.text.strip

      # Extract date from text like "Starts July 19, 2025 10:00 am"
      if (match = text.match(/Starts\s+(\w+\s+\d+,\s+\d{4})/))
        date_part = match[1]
        return Date.parse(date_part)
      end

      # Fallback to datetime attribute
      datetime_attr = datetime_element["datetime"]
      if datetime_attr && !datetime_attr.empty?
        if datetime_attr.include?("/")
          month, day, year = datetime_attr.split("/")
          return Date.new(year.to_i, month.to_i, day.to_i)
        else
          return Date.parse(datetime_attr)
        end
      end

      nil
    rescue ArgumentError => e
      log_warn("Could not parse datetime: #{e.message}")
      nil
    end

    def clean_event_name(name)
      name = name.gsub(/^\d+\s+/, "")             # Remove leading numbers
      name = name.gsub(/\s+@\s+.*$/, "")          # Remove venue info after @
      name = name.gsub(/\s+\d{1,2}:\d{2}\s+(am|pm).*$/i, "") # Remove time info
      name.strip
    end

    def extract_state(location)
      return nil if location.blank?

      match = location.match(/,\s*([A-Z]{2})$/)
      match ? match[1] : nil
    end
  end
end
