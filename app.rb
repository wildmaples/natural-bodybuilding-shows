require 'rubygems'
require 'bundler/setup'
require 'sinatra'
# require "sinatra/reloader" if development?  # Disabled to fix class loading
require 'rufus-scheduler'
require 'logger'
require 'concurrent-ruby'

require_relative 'app/shows.rb'
require_relative 'lib/scraper_manager.rb'

# Set up logging
logger = Logger.new(STDOUT)
logger.level = Logger::INFO

# Ensure db directory exists
Dir.mkdir('db') unless Dir.exist?('db')

# Initialize components
scraper_manager = ScraperManager.new

# Set up scheduler for daily scraping
scheduler = Rufus::Scheduler.new

# Schedule daily scraping at 6 AM with weekly historical updates
scheduler.cron '0 6 * * *' do
  logger.info "Starting daily scrape..."
  include_historical = Date.today.wday == 1 # Monday = include historical
  if include_historical
    logger.info "Monday scrape - including historical data"
  end
  scraper_manager.scrape_all_sources(include_historical: include_historical)
  logger.info "Daily scrape completed"
end

# Also scrape on startup if data is stale (include historical on first run)
Thread.new do
  begin
    if scraper_manager.data_needs_refresh?
      logger.info "Data is stale, scraping on startup..."
      scraper_manager.scrape_all_sources(include_historical: true)
      logger.info "Startup scraping completed"
    else
      logger.info "Data is fresh, skipping startup scrape"
    end
  rescue => e
    logger.error "Error during startup scrape: #{e.message}"
  end
end

# Production configuration for deployment
set :port, ENV['PORT'] || 4567
set :bind, '0.0.0.0'

get '/' do
  begin
    shows = Shows.new
    erb :index, locals: { 
      upcoming_shows: shows.get_upcoming_sorted,
      past_shows: shows.get_past_sorted,
      upcoming_count: shows.upcoming_count,
      past_count: shows.past_count,
      last_updated: shows.last_updated,
      data_freshness: scraper_manager.get_data_freshness,
      error: nil
    }
  rescue => e
    logger.error "Error in / route: #{e.message}"
    erb :index, locals: { 
      upcoming_shows: {},
      past_shows: {},
      upcoming_count: 0,
      past_count: 0,
      last_updated: nil,
      data_freshness: 'Error loading data',
      error: "Error loading shows: #{e.message}"
    }
  end
end

get '/about' do
  erb :about
end

# Health check endpoint
get '/health' do
  content_type :json
  shows = Shows.new
  {
    status: 'ok',
    last_updated: shows.last_updated,
    data_stale: shows.data_stale?
  }.to_json
end


