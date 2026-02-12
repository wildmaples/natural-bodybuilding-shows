require 'json'

module Scrapers
  class OcbScraper < BaseScraper
    API_URL = "https://ocbonline.com/wp-json/wp/v2/events".freeze
    FEDERATION = "OCB".freeze
    # Amateur = 9, Pro = 10 (exclude Workshops = 11)
    COMPETITION_CATEGORIES = "9,10".freeze

    def scrape
      log_info("Starting scrape from OCB REST API")

      entries = fetch_event_list
      return [] if entries.empty?

      log_info("Found #{entries.count} events from API")

      events = build_events_from_api(entries)
      fetch_event_details_concurrently(events)

      log_info("Parsed #{events.count} events with details")
      events
    end

    private

    def fetch_event_list
      entries = []
      page = 1

      loop do
        url = "#{API_URL}?per_page=100&event_category=#{COMPETITION_CATEGORIES}&page=#{page}"
        response = fetch_json(url)
        break if response.nil? || response.empty?

        entries.concat(response)
        break if response.length < 100

        page += 1
      end

      entries
    end

    def fetch_json(url)
      retries = 0
      begin
        uri = URI.parse(url)

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = (uri.scheme == 'https')
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
        http.open_timeout = 30
        http.read_timeout = 30

        request = Net::HTTP::Get.new(uri)
        request['Accept'] = 'application/json'

        response = http.request(request)

        unless response.is_a?(Net::HTTPSuccess)
          log_error("Failed to fetch #{url}: #{response.code}")
          return nil
        end

        JSON.parse(response.body)
      rescue StandardError => e
        retries += 1
        if retries <= MAX_RETRIES
          log_warn("Retry #{retries}/#{MAX_RETRIES} for #{url}: #{e.message}")
          sleep(RETRY_DELAY)
          retry
        end
        log_error("Error fetching #{url}: #{e.message}")
        nil
      end
    end

    def build_events_from_api(entries)
      entries.filter_map do |entry|
        name = strip_html(entry.dig("title", "rendered"))
        next if name.nil? || name.length < 5

        {
          name: name,
          date: nil,
          location: nil,
          state: nil,
          url: entry["link"] || "",
          federation: FEDERATION
        }
      end
    end

    def strip_html(html_str)
      return nil if html_str.nil?

      Nokogiri::HTML.fragment(html_str).text.strip
    end

    def fetch_event_details_concurrently(events)
      fetchable = events.select { |e| e[:url].present? }
      return if fetchable.empty?

      pool = Concurrent::FixedThreadPool.new([fetchable.size, 4].min)
      futures = {}

      fetchable.each do |event|
        futures[event] = Concurrent::Promises.future_on(pool) do
          fetch_event_details(event[:url])
        end
      end

      futures.each do |event, future|
        details = future.value(60)
        next unless details

        event[:date] = details[:date]
        event[:location] = details[:location]
        event[:state] = details[:state]
      end
    ensure
      pool&.shutdown
      pool&.wait_for_termination(10)
    end

    def fetch_event_details(event_url)
      html = fetch_page(event_url)
      return nil unless html

      date = extract_event_date(html)
      location = extract_event_location(html)

      {
        date: date,
        location: location,
        state: extract_state(location)
      }
    rescue StandardError => e
      log_warn("Failed to fetch details from #{event_url}: #{e.message}")
      nil
    end

    def extract_event_date(html)
      # OCB event pages show dates in MM-DD-YYYY format
      html.text.scan(/\b(\d{2}-\d{2}-\d{4})\b/).each do |match|
        month, day, year = match[0].split('-').map(&:to_i)
        return Date.new(year, month, day) if year >= 2025
      rescue ArgumentError
        next
      end

      nil
    end

    def extract_event_location(html)
      # OCB event pages show "City, State" in headings
      html.css("h3, h4").each do |heading|
        text = heading.text.strip
        next if text.empty? || text.length > 60

        if text.match?(/\A[A-Z][a-zA-Z\s.'-]+,\s+[A-Z][a-zA-Z\s]+\z/)
          return text
        end
      end

      nil
    end

    def extract_state(location)
      return nil if location.blank?

      match = location.match(/,\s*([A-Z]{2})$/)
      return match[1] if match

      # OCB uses full state names like "Wilmington, North Carolina"
      state_match = location.match(/,\s*(.+)$/)
      state_match ? US_STATES[state_match[1].strip] : nil
    end

    US_STATES = {
      "Alabama" => "AL", "Alaska" => "AK", "Arizona" => "AZ", "Arkansas" => "AR",
      "California" => "CA", "Colorado" => "CO", "Connecticut" => "CT", "Delaware" => "DE",
      "Florida" => "FL", "Georgia" => "GA", "Hawaii" => "HI", "Idaho" => "ID",
      "Illinois" => "IL", "Indiana" => "IN", "Iowa" => "IA", "Kansas" => "KS",
      "Kentucky" => "KY", "Louisiana" => "LA", "Maine" => "ME", "Maryland" => "MD",
      "Massachusetts" => "MA", "Michigan" => "MI", "Minnesota" => "MN", "Mississippi" => "MS",
      "Missouri" => "MO", "Montana" => "MT", "Nebraska" => "NE", "Nevada" => "NV",
      "New Hampshire" => "NH", "New Jersey" => "NJ", "New Mexico" => "NM", "New York" => "NY",
      "North Carolina" => "NC", "North Dakota" => "ND", "Ohio" => "OH", "Oklahoma" => "OK",
      "Oregon" => "OR", "Pennsylvania" => "PA", "Rhode Island" => "RI", "South Carolina" => "SC",
      "South Dakota" => "SD", "Tennessee" => "TN", "Texas" => "TX", "Utah" => "UT",
      "Vermont" => "VT", "Virginia" => "VA", "Washington" => "WA", "West Virginia" => "WV",
      "Wisconsin" => "WI", "Wyoming" => "WY"
    }.freeze
  end
end
