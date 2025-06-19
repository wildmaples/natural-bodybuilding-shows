# Natural Bodybuilding Shows Aggregator

An automated web application that scrapes and displays natural bodybuilding competition schedules from multiple federations in one convenient location.

## Features

- **Automated Daily Scraping**: Automatically updates show data every day at 6 AM
- **Multi-Federation Support**: Aggregates shows from OCB and WNBF federations
- **Scheduled Updates**: Fully automated data refresh with no manual intervention required
- **Sorted Display**: Shows chronologically ordered with upcoming events first
- **Modern Web Interface**: Clean, responsive design with federation badges
- **Health Monitoring**: API endpoint for monitoring data freshness
- **Error Handling**: Graceful handling of scraping failures and network issues

## Federations Supported

- **OCB (Organization of Competitive Bodybuilders)**: Amateur natural bodybuilding competitions
- **WNBF (World Natural Bodybuilding Federation)**: Professional natural bodybuilding competitions

## Installation

1. **Prerequisites**: Ruby 3.4.4+

2. **Install dependencies**:
   ```bash
   bundle install
   ```

3. **Create database directory**:
   ```bash
   mkdir -p db
   ```

4. **Initial data scrape**:
   ```bash
   bin/scrape all
   ```

## Usage

### Running the Web Application

```bash
# Development
ruby app.rb

# Production with Puma
bundle exec puma -p 4567
```

The application will be available at `http://localhost:4567`

### Manual Scraping (Development/Testing)

```bash
# Scrape all federations
bin/scrape all

# Scrape specific federation
bin/scrape wnbf
bin/scrape ocb
```

### API Endpoints

- `GET /` - Main show listing page
- `GET /about` - About page with project information  
- `GET /health` - Health check API (JSON response)

## How It Works

1. **Automated Scheduling**: Uses `rufus-scheduler` to run daily scrapes at 6 AM
2. **Concurrent Scraping**: Scrapes multiple federations in parallel using `concurrent-ruby`
3. **Data Storage**: Saves data as YAML files with timestamps for freshness tracking
4. **Dynamic Loading**: Automatically loads the most recent data files
5. **Stale Data Detection**: Checks if data is older than 24 hours and triggers refresh

## Data Structure

Show data is stored in YAML files with the following structure:

```yaml
validated: false
last_updated: 2024-01-15
events:
  "Show Name":
    date: 2024-03-15
    location: "City, State" 
    url: "https://registration-link.com"
    federation: "OCB"
```

## Configuration

Key configuration options in the code:

- `STALE_THRESHOLD_HOURS = 24` - Hours before data is considered stale
- Scrape schedule: `'0 6 * * *'` (6 AM daily)
- Data refresh cache: 5 minutes

## Development

### Project Structure

```
├── app.rb                 # Main Sinatra application
├── app/shows.rb          # Shows data management class
├── lib/
│   ├── scraper_manager.rb # Coordinates scraping operations
│   ├── scrape_ocb.rb     # OCB federation scraper
│   └── scrape_wnbf.rb    # WNBF federation scraper
├── bin/
│   ├── scrape            # Command-line scraping tool
│   └── utils.rb          # Utility functions
├── views/                # ERB templates
└── db/                   # YAML data files
```

### Running Tests

```bash
bundle exec rspec
```

## Deployment

For production deployment:

1. Set up automated process management (systemd, Docker, etc.)
2. Configure reverse proxy (nginx, Apache) if needed
3. Set appropriate environment variables
4. Ensure `db/` directory is writable
5. Monitor logs for scraping errors
6. Consider setting up monitoring for the `/health` endpoint

## Error Handling

The application handles various failure scenarios:

- Network timeouts during scraping
- Invalid HTML structure changes
- Missing or corrupted data files
- Concurrent access issues
- Graceful degradation when federations are unavailable

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure scrapers handle edge cases gracefully
5. Submit a pull request

## License

This project is for educational and personal use. Respect the terms of service of the scraped websites. 