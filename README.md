# Natural Bodybuilding Shows Aggregator

A comprehensive web application that automatically scrapes, archives, and displays natural bodybuilding competition schedules from multiple federations with advanced search and filtering capabilities.

## 🌟 Features

### 🔄 **Automated Data Management**
- **Daily Automated Scraping**: Updates show data every day at 6 AM
- **Automatic Archival**: Completed shows are automatically moved to archive
- **Weekly Historical Updates**: Historical data refresh every Monday
- **Startup Data Refresh**: Automatically scrapes if data is stale on startup

### 📊 **Past Shows Archive System**
- **Tab-Based Navigation**: Separate "Upcoming Shows" and "Past Shows" tabs
- **Historical Preservation**: Completed shows preserved in searchable archive
- **Automatic Date-Based Sorting**: Shows categorized by completion status
- **Archive Timestamps**: Shows marked with archival dates

### 🔍 **Advanced Search & Filtering**
- **Real-Time Search**: Instant filtering as you type
- **Multi-Criteria Filtering**:
  - Show name search
  - Location/venue search
  - Date range filtering
  - Federation filtering (OCB, WNBF, All)
- **Dynamic Result Counts**: Live updates of filtered results
- **Cross-Tab Search**: Search functionality works across both upcoming and past shows

### 🎨 **Modern User Interface**
- **Responsive Design**: Works on desktop, tablet, and mobile
- **Clean Tab Interface**: Intuitive navigation between upcoming and past shows
- **Visual Federation Badges**: OCB (blue) and WNBF (orange) color coding
- **Real-Time Result Counter**: Shows filtered vs total results
- **Empty State Handling**: Helpful messages when no results found

### 📈 **Monitoring & Health**
- **Health Check API**: Monitor application status and data freshness
- **Comprehensive Logging**: Detailed logs for scraping and archival operations
- **Error Handling**: Graceful handling of network issues and parsing errors
- **Data Freshness Tracking**: Automatic detection of stale data

## 🚀 Installation

### Prerequisites
- Ruby 3.4.4+
- Bundler gem

### Setup Steps

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd natural-bodybuilding-shows
   ```

2. **Install dependencies**:
   ```bash
   bundle install
   ```

3. **Create database directory**:
   ```bash
   mkdir -p db
   ```

4. **Initial data scrape** (includes historical data):
   ```bash
   bin/scrape all
   ```

5. **Generate sample past shows** (for demonstration):
   ```bash
   ruby bin/create_sample_past_shows
   ```

## 🎯 Usage

### Running the Web Application

```bash
# Development
ruby app.rb

# Production with background process
nohup ruby app.rb > app.log 2>&1 &
```

The application will be available at `http://localhost:4567`

### Manual Scraping Operations

```bash
# Scrape all federations (current shows only)
bin/scrape all

# Scrape specific federation
bin/scrape wnbf
bin/scrape ocb

# Scrape historical shows (when available)
ruby bin/scrape_historical

# Create sample past shows for testing
ruby bin/create_sample_past_shows
```

### Web Interface Navigation

1. **Home Page** (`/`):
   - Tab-based navigation: "Upcoming Shows" and "Past Shows"
   - Advanced search and filtering options
   - Real-time result updates
   - Show details with federation badges

2. **About Page** (`/about`):
   - Project information
   - Federation details with official links
   - Usage instructions

3. **Health Check** (`/health`):
   - JSON API endpoint for monitoring
   - Data freshness status
   - Application health metrics

## 🛠️ API Endpoints

| Endpoint | Method | Description | Response |
|----------|--------|-------------|----------|
| `/` | GET | Main show listing with tabs | HTML |
| `/about` | GET | About page with federation info | HTML |
| `/health` | GET | Health check and status | JSON |

### Health Check Response
```json
{
  "status": "ok",
  "last_updated": "2025-06-19 12:30:00 -0400",
  "data_stale": false
}
```

## ⚙️ How It Works

### Automated Scraping Process
1. **Daily Schedule**: Runs at 6 AM using `rufus-scheduler`
2. **Archive Completed Shows**: Moves past events to historical archive
3. **Parallel Federation Scraping**: OCB and WNBF scraped concurrently
4. **Data Validation**: Ensures scraped data integrity
5. **Historical Updates**: Weekly refresh of historical archives

### Data Flow
```
Federation Websites → Scrapers → Archive Past Shows → Save Current Shows → Web Interface
```

### Archival System
- **Pre-Scrape Archive**: Before scraping new data, completed shows are archived
- **Date-Based Logic**: Shows with dates < today are moved to archive
- **Historical Files**: Archived shows saved to `*_historical_events_*.yml`
- **Archive Merging**: New archived shows merged with existing historical data

## 📁 Data Structure

### Current Shows Files
```yaml
# db/ocb_events_2025-06-19.yml
events:
  "Show Name":
    date: 2025-07-15
    location: "City, State"
    url: "https://registration-link.com"
    federation: "OCB"
```

### Historical Shows Files
```yaml
# db/ocb_historical_events_2025-06-19.yml
events:
  "Completed Show":
    date: 2025-01-15
    location: "City, State"
    url: "https://registration-link.com"
    federation: "OCB"
    archived_on: 2025-06-19
```

## 🏗️ Project Structure

```
├── app.rb                          # Main Sinatra application
├── app/shows.rb                    # Shows data management with archival support
├── lib/
│   ├── scraper_manager.rb          # Coordinates scraping and archival
│   ├── scrape_ocb.rb              # OCB scraper with auto-archival
│   ├── scrape_wnbf.rb             # WNBF scraper with auto-archival
│   └── scrape_historical_ocb.rb    # Historical OCB events scraper
├── bin/
│   ├── scrape                      # Command-line scraping tool
│   ├── scrape_historical          # Historical scraping script
│   ├── create_sample_past_shows   # Sample data generator
│   └── utils.rb                   # Utility functions
├── views/
│   ├── index.erb                  # Main page with tabs and search
│   └── about.erb                  # About page with federation links
└── db/                            # YAML data files (current & historical)
```

## 🎨 User Interface Features

### Search Interface
- **Show Name Search**: Find competitions by name (e.g., "Naturalmania")
- **Location Search**: Filter by city, state, or venue
- **Federation Filter**: Select OCB, WNBF, or All federations
- **Date Range Picker**: Filter shows within specific date ranges
- **Clear All Button**: Reset all search filters instantly

### Tab Navigation
- **Upcoming Shows Tab**: Future competitions with bright styling
- **Past Shows Tab**: Historical competitions with muted styling
- **Dynamic Counters**: Live count of shows in each tab
- **Search Across Tabs**: Filtering works independently for each tab

### Show Display
- **Federation Badges**: Color-coded OCB (blue) and WNBF (orange) badges
- **Clickable Links**: Direct links to show registration pages
- **Location Details**: City, state, and venue information
- **Date Formatting**: Human-readable date display

## 🔧 Configuration

### Application Settings
```ruby
# Data staleness threshold
STALE_THRESHOLD_HOURS = 24

# Scraping schedule (6 AM daily)
scheduler.cron '0 6 * * *'

# Historical updates (Mondays)
include_historical = Date.today.wday == 1
```

### Customizable Options
- Scraping schedule timing
- Data refresh intervals
- Search result limits
- UI styling and colors

## 🚀 Deployment

### Production Setup
1. **Process Management**: Use systemd, supervisor, or Docker
2. **Web Server**: Configure nginx or Apache reverse proxy
3. **Database**: Ensure `db/` directory has write permissions
4. **Monitoring**: Set up health check monitoring
5. **Logging**: Configure log rotation for `app.log`

### Docker Deployment (Optional)
```dockerfile
FROM ruby:3.4.4
WORKDIR /app
COPY Gemfile* ./
RUN bundle install
COPY . .
EXPOSE 4567
CMD ["ruby", "app.rb"]
```

### Environment Variables
```bash
RACK_ENV=production
PORT=4567
```

## 🧪 Development & Testing

### Development Setup
```bash
# Install development dependencies
bundle install

# Run with auto-reload
ruby app.rb

# Test scrapers individually
ruby -r ./lib/scrape_ocb.rb -e "puts OcbScraper.new.scrape_events.count"
```

### Manual Testing
```bash
# Test archival functionality
ruby -e "require './lib/scrape_ocb'; OcbScraper.new.send(:archive_completed_shows)"

# Verify data loading
ruby -r ./app/shows.rb -e "s = Shows.new; puts 'Upcoming: #{s.upcoming_count}, Past: #{s.past_count}'"
```

## 🔍 Troubleshooting

### Common Issues

**Class Loading Errors**:
- Ensure `load` statements are used instead of `require_relative` in `app.rb`
- Restart the application completely if methods aren't recognized

**Missing Past Shows**:
- Run `ruby bin/create_sample_past_shows` to generate sample data
- Check for `*_historical_events_*.yml` files in `db/` directory

**Search Not Working**:
- Verify JavaScript is enabled in browser
- Check browser console for errors
- Ensure proper data attributes in HTML

**Scraping Failures**:
- Check `app.log` for detailed error messages
- Verify federation website accessibility
- Test network connectivity

## 📝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Add comprehensive tests for new functionality
4. Ensure scrapers handle edge cases and website changes
5. Update README.md with new features
6. Submit a pull request

### Development Guidelines
- Follow Ruby style conventions
- Add error handling for external dependencies
- Include logging for debugging
- Test both upcoming and past show functionality
- Verify responsive design on mobile devices

## 📊 Current Data Coverage

- **Total Shows**: ~139 shows (133 upcoming, 6 past)
- **OCB Events**: ~117 current competitions
- **WNBF Events**: ~16 current competitions  
- **Historical Archive**: Sample past shows from Jan-Jun 2025
- **Update Frequency**: Daily at 6 AM with weekly historical refresh

## 🔗 Federation Links

- **OCB**: https://ocbonline.com/
- **WNBF**: https://worldnaturalbb.com/

## 📄 License

This project is for educational and personal use. Please respect the terms of service of the scraped websites and use responsibly.

## 🎯 Future Enhancements

- Additional federation support (NPC, INBA, etc.)
- Email notifications for new shows
- Calendar export functionality
- Competition result tracking
- Competitor profiles and statistics
- Mobile app development 