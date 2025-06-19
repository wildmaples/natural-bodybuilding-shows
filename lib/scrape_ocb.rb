require 'uri'
require 'net/http'
require 'nokogiri'
require 'yaml/store'
require 'date'
require 'logger'
require_relative '../bin/utils'

class OcbScraper
  BASE_URL = "https://ocbonline.com/event_schedule.php"
  
  def initialize(logger = nil)
    @logger = logger || Logger.new(STDOUT)
  end

  def scrape
    @logger.info "Starting OCB scrape from #{BASE_URL}"
    
    html = fetch_page
    return false unless html
    
    events = parse_events(html)
    
    # Archive past shows before saving new ones
    archive_completed_shows
    
    save_events(events)
    
    @logger.info "OCB scrape completed. Found #{events.count} events"
    true
  end

  def scrape_events
    @logger.info "Starting OCB scrape from #{BASE_URL}"
    
    html = fetch_page
    return {} unless html
    
    parse_events(html)
  end

  def save_events(events)
    # Archive past shows first
    archive_completed_shows
    
    date_today = Date.today
    filename = "db/ocb_events_#{date_today}.yml"
    
    Utils.store_as_yaml(filename, events)
    @logger.info "Saved #{events.count} OCB events to #{filename}"
  rescue => e
    @logger.error "Failed to save OCB events: #{e.message}"
    raise
  end

  private

  def archive_completed_shows
    # Find the most recent OCB events file
    ocb_files = Dir.glob("db/ocb_events_*.yml").sort
    return if ocb_files.empty?
    
    latest_file = ocb_files.last
    @logger.info "Checking for completed shows in #{latest_file}"
    
    begin
      existing_data = YAML.load_file(latest_file, permitted_classes: [Date])
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
    historical_filename = "db/ocb_historical_events_#{date_today}.yml"
    
    # Load existing historical events if file exists
    existing_historical = {}
    if File.exist?(historical_filename)
      begin
        historical_data = YAML.load_file(historical_filename, permitted_classes: [Date])
        existing_historical = historical_data&.dig("events") || historical_data || {}
      rescue => e
        @logger.warn "Failed to load existing historical data: #{e.message}"
      end
    end
    
    # Merge past events with existing historical events
    merged_historical = existing_historical.merge(past_events)
    
    Utils.store_as_yaml(historical_filename, merged_historical)
    @logger.info "Archived #{past_events.count} completed OCB shows to #{historical_filename}"
  end

  def fetch_page
    uri = URI.parse(BASE_URL)
    response = Net::HTTP.get_response(uri)
    
    unless response.is_a?(Net::HTTPSuccess)
      @logger.error "Failed to fetch OCB page: #{response.code} #{response.message}"
      return nil
    end
    
    Nokogiri::HTML(response.body)
  rescue => e
    @logger.error "Error fetching OCB page: #{e.message}"
    nil
  end

  def parse_events(html)
    events = html.xpath("//td[@data-title]")
    ocb_events = {}

    # OCB site organizes their shows in a HTML table with 3 columns
    # containing the date, location and name (with url)
    events.each_slice(3) do |date_cell, location_cell, name_cell|
      next unless date_cell && location_cell && name_cell
      
      begin
        date = date_cell.text.strip
        location = location_cell.text.strip
        name_element = name_cell.children[1]
        
        next unless name_element
        
        name = name_element.text.strip
        url = name_element["href"]&.strip
        
        next if name.empty?
        
        ocb_events[name] = {
          "date" => Utils.convert_date(date),
          "location" => location,
          "url" => url || "",
          "federation" => "OCB"
        }
      rescue => e
        @logger.warn "Skipping OCB event due to parsing error: #{e.message}"
      end
    end

    ocb_events
  end
end
