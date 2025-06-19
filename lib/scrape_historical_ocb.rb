require 'open-uri'
require 'nokogiri'
require 'yaml'
require 'date'
require 'logger'

class HistoricalOcbScraper
  def initialize
    @logger = Logger.new('app.log')
    @base_url = 'https://ocbonline.com/results.php?year=2025'
  end

  def scrape_historical_events
    @logger.info "Starting historical OCB scrape from #{@base_url}"
    
    begin
      doc = Nokogiri::HTML(URI.open(@base_url))
      events = []
      
      # Find the results table - structure similar to 2024 page
      table_rows = doc.css('table tr')
      
      table_rows.each do |row|
        cells = row.css('td')
        next if cells.length < 3
        
        date_cell = cells[0]&.text&.strip
        location_cell = cells[1]&.text&.strip
        name_cell = cells[2]
        
        next unless date_cell && location_cell && name_cell
        
        # Parse date
        begin
          event_date = Date.strptime(date_cell, '%m/%d/%Y')
        rescue => e
          @logger.warn "Invalid date format: #{date_cell}"
          next
        end
        
        # Only include past events (before today)
        next unless event_date < Date.today
        
        # Extract event name and URL
        event_link = name_cell.css('a').first
        event_name = event_link&.text&.strip || name_cell.text.strip
        event_url = event_link ? "https://ocbonline.com/#{event_link['href']}" : nil
        
        # Clean up location
        location = location_cell.gsub(/\s+/, ' ')
        
        events << {
          name: event_name,
          date: event_date,
          location: location,
          url: event_url,
          federation: 'OCB'
        }
      end
      
      @logger.info "Historical OCB scrape completed. Found #{events.length} past events"
      events
      
    rescue => e
      @logger.error "Error scraping historical OCB events: #{e.message}"
      []
    end
  end

  def save_historical_events(events)
    return if events.empty?
    
    filename = "db/ocb_historical_events_#{Date.today}.yml"
    
    data = {
      'validated' => false,
      'last_updated' => Date.today,
      'events' => {}
    }
    
    events.each do |event|
      data['events'][event[:name]] = {
        'date' => event[:date],
        'location' => event[:location],
        'url' => event[:url],
        'federation' => event[:federation]
      }
    end
    
    File.write(filename, data.to_yaml)
    @logger.info "Saved #{events.length} historical OCB events to #{filename}"
  end
end 