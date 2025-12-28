namespace :scrape do
  desc "Scrape all federation websites for events"
  task all: :environment do
    puts "Starting full scrape..."
    results = ScraperManager.new.scrape_all

    results.each do |result|
      status = result[:success] ? "✓" : "✗"
      puts "#{status} #{result[:source]}: #{result[:count]} events"
    end

    total = results.sum { |r| r[:count] }
    puts "\nTotal events scraped: #{total}"
    puts "Database now contains: #{Event.count} events"
  end

  desc "Scrape OCB events only"
  task ocb: :environment do
    puts "Starting OCB scrape..."
    scraper = Scrapers::OcbScraper.new
    events = scraper.scrape_and_save
    puts "Found #{events.count} OCB events"
    puts "Database now contains: #{Event.where(federation: 'OCB').count} OCB events"
  end

  desc "Scrape WNBF events only"
  task wnbf: :environment do
    puts "Starting WNBF scrape..."
    scraper = Scrapers::WnbfScraper.new
    events = scraper.scrape_and_save
    puts "Found #{events.count} WNBF events"
    puts "Database now contains: #{Event.where(federation: 'WNBF').count} WNBF events"
  end

  desc "Show data freshness status"
  task status: :environment do
    manager = ScraperManager.new
    puts "Data freshness: #{manager.data_freshness}"
    puts "Needs refresh: #{manager.data_needs_refresh? ? 'Yes' : 'No'}"
    puts "\nEvent counts:"
    puts "  OCB: #{Event.where(federation: 'OCB').count}"
    puts "  WNBF: #{Event.where(federation: 'WNBF').count}"
    puts "  Total: #{Event.count}"
  end
end
