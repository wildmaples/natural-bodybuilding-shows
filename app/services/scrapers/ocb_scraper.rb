module Scrapers
  class OcbScraper < BaseScraper
    BASE_URL = "https://ocbonline.com/event_schedule.php".freeze
    FEDERATION = "OCB".freeze

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
      cells = html.xpath("//td[@data-title]")

      # OCB site organizes shows in HTML table with 3 columns: date, location, name (with url)
      cells.each_slice(3) do |date_cell, location_cell, name_cell|
        next unless date_cell && location_cell && name_cell

        event_data = parse_event_row(date_cell, location_cell, name_cell)
        events << event_data if event_data
      end

      events
    end

    def parse_event_row(date_cell, location_cell, name_cell)
      date_str = date_cell.text.strip
      location = location_cell.text.strip
      name_element = name_cell.children[1]

      return nil unless name_element

      name = name_element.text.strip
      url = name_element["href"]&.strip

      return nil if name.empty?

      {
        name: name,
        date: convert_date(date_str),
        location: location,
        state: extract_state(location),
        url: url || "",
        federation: FEDERATION
      }
    rescue StandardError => e
      log_warn("Skipping event due to parsing error: #{e.message}")
      nil
    end

    def extract_state(location)
      return nil if location.blank?

      # Try to extract state abbreviation from end of location string
      match = location.match(/,\s*([A-Z]{2})$/)
      match ? match[1] : nil
    end
  end
end
