require 'logger'
require 'concurrent-ruby'
require_relative 'scrape_ocb'
require_relative 'scrape_wnbf'
require_relative 'scrape_historical_ocb'

class ScraperManager
  def initialize
    @logger = Logger.new('app.log')
  end

  def scrape_all_sources(include_historical: false)
    @logger.info "Starting scrape of all sources..."
    
    # Parallel scraping for current events
    executor = Concurrent::ThreadPoolExecutor.new(min_threads: 2, max_threads: 4)
    
    ocb_future = Concurrent::Future.execute(executor: executor) do
      scraper = OcbScraper.new
      events = scraper.scrape_events
      scraper.save_events(events)
      { source: 'OCB', success: !events.empty?, count: events.length }
    end

    wnbf_future = Concurrent::Future.execute(executor: executor) do
      scraper = WnbfScraper.new
      events = scraper.scrape_events
      scraper.save_events(events)
      { source: 'WNBF', success: !events.empty?, count: events.length }
    end

    # Wait for current events to complete
    results = [ocb_future.value, wnbf_future.value]
    
    # Scrape historical events if requested
    if include_historical
      @logger.info "Including historical events in scrape..."
      historical_scraper = HistoricalOcbScraper.new
      historical_events = historical_scraper.scrape_historical_events
      historical_scraper.save_historical_events(historical_events)
      
      results << { 
        source: 'OCB Historical', 
        success: !historical_events.empty?, 
        count: historical_events.length 
      }
    end

    executor.shutdown

    # Log results
    results.each do |result|
      status = result[:success] ? 'success' : 'failed'
      @logger.info "#{result[:source]} scrape #{status}. Found #{result[:count]} events"
    end

    overall_success = results.any? { |r| r[:success] }
    @logger.info "Scraping completed. #{results.map { |r| "#{r[:source]}: #{r[:success] ? 'success' : 'failed'}" }.join(', ')}"
    
    overall_success
  end

  def data_needs_refresh?
    latest_file = Dir.glob('db/*_events_*.yml').max_by { |f| File.mtime(f) }
    return true unless latest_file
    
    last_update = File.mtime(latest_file)
    Time.now - last_update > 24 * 60 * 60 # 24 hours
  end

  def get_data_freshness
    latest_file = Dir.glob('db/*_events_*.yml').max_by { |f| File.mtime(f) }
    return 'No data available' unless latest_file
    
    last_update = File.mtime(latest_file)
    hours_ago = ((Time.now - last_update) / 3600).round
    
    if hours_ago < 1
      'Less than an hour ago'
    elsif hours_ago < 24
      "#{hours_ago} hour#{hours_ago == 1 ? '' : 's'} ago"
    else
      days_ago = (hours_ago / 24).round
      "#{days_ago} day#{days_ago == 1 ? '' : 's'} ago"
    end
  end


end 