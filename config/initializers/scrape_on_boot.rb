Rails.application.config.after_initialize do
  next unless Rails.env.production?

  if Event.count.zero?
    # No data at all — scrape synchronously so the site isn't empty on first request
    Rails.logger.info("[ScrapeOnBoot] No events found, scraping synchronously...")
    ScraperManager.new.scrape_all
  else
    ScrapeEventsJob.perform_later
  end
rescue => e
  Rails.logger.error("[ScrapeOnBoot] Failed: #{e.message}")
end
