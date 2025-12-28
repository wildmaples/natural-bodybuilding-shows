class ScraperManager
  STALE_THRESHOLD_HOURS = 24

  def initialize(logger: nil)
    @logger = logger || Rails.logger
  end

  def scrape_all
    log_info("Starting scrape of all sources...")

    results = scrape_in_parallel

    log_results(results)
    overall_success = results.any? { |r| r[:success] }

    log_info("Scraping completed. Overall success: #{overall_success}")
    results
  end

  def data_needs_refresh?
    last_event = Event.order(updated_at: :desc).first
    return true unless last_event

    Time.current - last_event.updated_at > STALE_THRESHOLD_HOURS.hours
  end

  def data_freshness
    last_event = Event.order(updated_at: :desc).first
    return "No data available" unless last_event

    hours_ago = ((Time.current - last_event.updated_at) / 1.hour).round

    if hours_ago < 1
      "Less than an hour ago"
    elsif hours_ago < 24
      "#{hours_ago} hour#{'s' unless hours_ago == 1} ago"
    else
      days_ago = (hours_ago / 24).round
      "#{days_ago} day#{'s' unless days_ago == 1} ago"
    end
  end

  private

  def scrape_in_parallel
    results = []
    executor = Concurrent::ThreadPoolExecutor.new(min_threads: 2, max_threads: 4)

    futures = scrapers.map do |scraper_class|
      Concurrent::Future.execute(executor: executor) do
        scrape_source(scraper_class)
      end
    end

    results = futures.map(&:value)

    executor.shutdown
    executor.wait_for_termination(60)

    results
  end

  def scrapers
    [
      Scrapers::OcbScraper,
      Scrapers::WnbfScraper
    ]
  end

  def scrape_source(scraper_class)
    scraper = scraper_class.new
    events = scraper.scrape_and_save

    {
      source: scraper_class.name.demodulize.gsub("Scraper", ""),
      success: events.any?,
      count: events.count
    }
  rescue StandardError => e
    log_error("Error scraping #{scraper_class.name}: #{e.message}")
    {
      source: scraper_class.name.demodulize.gsub("Scraper", ""),
      success: false,
      count: 0,
      error: e.message
    }
  end

  def log_results(results)
    results.each do |result|
      status = result[:success] ? "success" : "failed"
      log_info("#{result[:source]} scrape #{status}. Found #{result[:count]} events")
      log_error("  Error: #{result[:error]}") if result[:error]
    end
  end

  def log_info(message)
    @logger.info("[ScraperManager] #{message}")
  end

  def log_error(message)
    @logger.error("[ScraperManager] #{message}")
  end
end
