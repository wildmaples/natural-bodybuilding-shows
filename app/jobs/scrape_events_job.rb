class ScrapeEventsJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info("Starting scheduled event scrape...")
    results = ScraperManager.new.scrape_all

    total = results.sum { |r| r[:count] }
    success_count = results.count { |r| r[:success] }

    Rails.logger.info("Scheduled scrape completed: #{success_count}/#{results.count} sources, #{total} events")
  end
end
