require 'uri'
require 'net/http'
require 'nokogiri'
require 'yaml/store'
require 'date'
require 'logger'
require_relative '../bin/utils'

class WnbfScraper
  BASE_URL = "https://worldnaturalbb.com/usa-events/"
  
  def initialize(logger = nil)
    @logger = logger || Logger.new(STDOUT)
  end

  def scrape
    @logger.info "Starting WNBF scrape from #{BASE_URL}"
    
    html = fetch_page
    return false unless html
    
    events = parse_events(html)
    
    # Archive past shows before saving new ones
    archive_completed_shows
    
    save_events(events)
    
    @logger.info "WNBF scrape completed. Found #{events.count} events"
    true
  end

  def scrape_events
    @logger.info "Starting WNBF scrape from #{BASE_URL}"
    
    html = fetch_page
    return {} unless html
    
    parse_events(html)
  end

  def save_events(events)
    # Archive past shows first
    archive_completed_shows
    
    date_today = Date.today
    filename = "db/wnbf_events_#{date_today}.yml"
    
    Utils.store_as_yaml(filename, events)
    @logger.info "Saved #{events.count} WNBF events to #{filename}"
  rescue => e
    @logger.error "Failed to save WNBF events: #{e.message}"
    raise
  end

  private

  def archive_completed_shows
    # Find the most recent WNBF events file
    wnbf_files = Dir.glob("db/wnbf_events_*.yml").sort
    return if wnbf_files.empty?
    
    latest_file = wnbf_files.last
    @logger.info "Checking for completed shows in #{latest_file}"
    
    begin
      existing_data = YAML.load_file(latest_file, permitted_classes: [Date], aliases: true)
      existing_events = existing_data&.dig("events") || existing_data || {}
      
      past_events = {}
      upcoming_events = {}
      today = Date.today
      
      existing_events.each do |name, event_data|
        event_date = event_data["date"]
        
        # Check if event date has passed
        if event_date.is_a?(Date) && event_date < today
          past_events[name] = event_data.merge("archived_on" => today)
          @logger.info "Archiving completed show: #{name} (#{event_date})"
        else
          upcoming_events[name] = event_data
        end
      end
      
      # Save past events to historical archive if any found
      if past_events.any?
        save_to_historical_archive(past_events)
        
        # Update the current file to remove past events
        if upcoming_events.any?
          Utils.store_as_yaml(latest_file, upcoming_events)
          @logger.info "Removed #{past_events.count} completed shows from current events"
        end
      end
      
    rescue => e
      @logger.warn "Failed to archive completed shows: #{e.message}"
    end
  end

  def save_to_historical_archive(past_events)
    date_today = Date.today
    historical_filename = "db/wnbf_historical_events_#{date_today}.yml"
    
    # Load existing historical events if file exists
    existing_historical = {}
    if File.exist?(historical_filename)
      begin
        historical_data = YAML.load_file(historical_filename, permitted_classes: [Date], aliases: true)
        existing_historical = historical_data&.dig("events") || historical_data || {}
      rescue => e
        @logger.warn "Failed to load existing historical data: #{e.message}"
      end
    end
    
    # Merge past events with existing historical events
    merged_historical = existing_historical.merge(past_events)
    
    Utils.store_as_yaml(historical_filename, merged_historical)
    @logger.info "Archived #{past_events.count} completed WNBF shows to #{historical_filename}"
  end

  def fetch_page
    uri = URI.parse(BASE_URL)
    response = Net::HTTP.get_response(uri)
    
    unless response.is_a?(Net::HTTPSuccess)
      @logger.error "Failed to fetch WNBF page: #{response.code} #{response.message}"
      return nil
    end
    
    Nokogiri::HTML(response.body)
  rescue => e
    @logger.error "Error fetching WNBF page: #{e.message}"
    nil
  end

  def parse_events(html)
    wnbf_events = {}
    
    # Look for event containers using the new Bricks theme structure
    events = html.css('.fr-timeline-charlie__meta')
    
    @logger.info "Found #{events.count} event containers on page"
    
    events.each do |event|
      begin
        # Extract event name from title link
        title_link = event.css('h2 a').first
        next unless title_link
        
        name = title_link.text.strip
        url = title_link['href']
        
        next if name.empty? || name.length < 5
        
        # Extract date from datetime element
        datetime_element = event.css('time.event__start-date').first
        date_value = datetime_element ? extract_date_from_datetime(datetime_element) : "TBA"
        
        # Convert to Date object if it's a string, otherwise use as-is
        parsed_date = date_value.is_a?(Date) ? date_value : Utils.convert_date(date_value)
        
        # Extract location from individual event page
        location = fetch_event_location(url)
        
        # Clean up the name and ensure it's valid
        name = clean_event_name(name)
        next if name.length < 5
        
        wnbf_events[name] = {
          "date" => parsed_date,
          "location" => location,
          "url" => url || "",
          "federation" => "WNBF"
        }
        
        @logger.debug "Added event: #{name} on #{parsed_date} at #{location}"
      rescue => e
        @logger.warn "Skipping WNBF event due to parsing error: #{e.message}"
      end
    end

    wnbf_events
  end

  def fetch_event_location(event_url)
    return "TBA" unless event_url
    
    begin
      uri = URI.parse(event_url)
      response = Net::HTTP.get_response(uri)
      
      unless response.is_a?(Net::HTTPSuccess)
        @logger.warn "Failed to fetch event page for location: #{response.code}"
        return "TBA"
      end
      
      html = Nokogiri::HTML(response.body)
      
      # Look for location information
      location_element = html.css('.main-event__location-text').first
      if location_element
        location = location_element.text.strip
        return location unless location.empty?
      end
      
      # Fallback: look for any element with location in class name
      location_elements = html.css('[class*="location"]')
      location_elements.each do |el|
        location = el.text.strip
        return location if location.length > 0 && location.length < 100
      end
      
      "TBA"
    rescue => e
      @logger.warn "Failed to fetch location for event: #{e.message}"
      "TBA"
    end
  end

  def extract_date_from_datetime(datetime_element)
    # First try to extract date from text content (more reliable)
    text = datetime_element.text.strip
    
    # Extract date from text like "Starts July 19, 2025 10:00 am"
    if text.match(/Starts\s+(\w+\s+\d+,\s+\d{4})/)
      date_part = text.match(/Starts\s+(\w+\s+\d+,\s+\d{4})/)[1]
      begin
        return Date.parse(date_part)
      rescue ArgumentError
        @logger.warn "Could not parse date from text: #{date_part}"
      end
    end
    
    # Fallback to datetime attribute if text parsing fails
    datetime_attr = datetime_element['datetime']
    if datetime_attr && !datetime_attr.empty?
      # Parse the date format (MM/DD/YYYY)
      begin
        if datetime_attr.include?('/')
          month, day, year = datetime_attr.split('/')
          return Date.new(year.to_i, month.to_i, day.to_i)
        else
          return Date.parse(datetime_attr)
        end
      rescue ArgumentError
        @logger.warn "Could not parse datetime attribute: #{datetime_attr}"
      end
    end
    
    "TBA"
  end

  def clean_event_name(name)
    # Remove common prefixes/suffixes and clean up
    name = name.gsub(/^\d+\s+/, '') # Remove leading numbers
    name = name.gsub(/\s+@\s+.*$/, '') # Remove venue info after @
    name = name.gsub(/\s+\d{1,2}:\d{2}\s+(am|pm).*$/i, '') # Remove time info
    name = name.strip
    
    # Return the name if it looks like a valid event
    name.length > 5 ? name : ""
  end
end
