require 'net/http'
require 'openssl'
require 'nokogiri'

module Scrapers
  class BaseScraper
    MAX_RETRIES = 3
    RETRY_DELAY = 2

    def initialize(logger: nil)
      @logger = logger || Rails.logger
    end

    def scrape
      raise NotImplementedError, 'Subclasses must implement #scrape'
    end

    def scrape_and_save
      events = scrape
      save_events(events) if events.any?
      events
    end

    protected

    def fetch_page(url)
      retries = 0
      begin
        uri = URI.parse(url)

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = (uri.scheme == 'https')
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE # Allow sites with cert issues
        http.open_timeout = 30
        http.read_timeout = 30

        request = Net::HTTP::Get.new(uri)
        request['User-Agent'] =
          'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
        request['Accept'] = 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8'
        request['Accept-Language'] = 'en-US,en;q=0.5'
        request['Connection'] = 'keep-alive'

        response = http.request(request)

        unless response.is_a?(Net::HTTPSuccess)
          log_error("Failed to fetch #{url}: #{response.code} #{response.message}")
          return nil
        end

        Nokogiri::HTML(response.body)
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

    def save_events(events)
      events.each do |event_data|
        upsert_event(event_data)
      end
      log_info("Saved #{events.count} events to database")
    end

    def upsert_event(event_data)
      event = Event.find_or_initialize_by(
        name: event_data[:name],
        date: event_data[:date],
        federation: event_data[:federation]
      )

      event.assign_attributes(
        location: event_data[:location],
        state: event_data[:state],
        url: event_data[:url]
      )

      event.save!
    rescue ActiveRecord::RecordInvalid => e
      log_warn("Failed to save event #{event_data[:name]}: #{e.message}")
    end

    def log_info(message)
      @logger.info("[#{self.class.name}] #{message}")
    end

    def log_warn(message)
      @logger.warn("[#{self.class.name}] #{message}")
    end

    def log_error(message)
      @logger.error("[#{self.class.name}] #{message}")
    end

    def convert_date(date_str)
      return nil if date_str.nil? || date_str == 'TBA' || date_str.strip.empty?

      # Handle date ranges - use first date only
      if date_str.include?('-') && !date_str.match?(/^\d{4}-\d{2}-\d{2}$/)
        idx = date_str.index('-') - 1
        date_str = date_str[0..idx].strip
      end

      if date_str.include?('/')
        # MM/DD/YYYY format
        parts = date_str.split('/')
        return nil if parts.length != 3

        Date.new(parts[2].to_i, parts[0].to_i, parts[1].to_i)
      else
        Date.parse(date_str)
      end
    rescue ArgumentError, TypeError => e
      log_warn("Could not parse date '#{date_str}': #{e.message}")
      nil
    end
  end
end
