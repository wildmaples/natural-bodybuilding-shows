require 'yaml'
require 'date'

class Shows
  STALE_THRESHOLD_HOURS = 24

  def initialize
    @shows = nil
    @last_loaded = nil
  end

  def get_sorted
    load_data
    @shows.sort_by { |name, data| sort_key_for_date(data["date"]) }.to_h
  end

  def get_upcoming_sorted
    load_data
    upcoming = @shows.select { |name, data| is_upcoming?(data["date"]) }
    upcoming.sort_by { |name, data| sort_key_for_date(data["date"]) }.to_h
  end

  def get_past_sorted
    load_data
    past = @shows.select { |name, data| is_past?(data["date"]) }
    past.sort_by { |name, data| sort_key_for_date(data["date"]) }.reverse.to_h
  end

  def get
    load_data
    @shows
  end

  def last_updated
    most_recent_file_date
  end

  def data_stale?
    return true unless last_updated
    
    Time.now - last_updated > STALE_THRESHOLD_HOURS * 3600
  end

  def upcoming_count
    load_data
    @shows.count { |name, data| is_upcoming?(data["date"]) }
  end

  def past_count
    load_data
    @shows.count { |name, data| is_past?(data["date"]) }
  end

  private

  def load_data
    # Only reload if we haven't loaded or if data is stale
    return @shows if @shows && @last_loaded && (Time.now - @last_loaded) < 300 # 5 minutes

    @shows = {}
    
    # Load current WNBF data
    wnbf_file = most_recent_file("wnbf_events")
    if wnbf_file && File.exist?(wnbf_file)
      wnbf_data = YAML.load_file(wnbf_file, permitted_classes: [Date])
      @shows.merge!(wnbf_data["events"] || {}) if wnbf_data
    end

    # Load current OCB data  
    ocb_file = most_recent_file("ocb_events")
    if ocb_file && File.exist?(ocb_file)
      ocb_data = YAML.load_file(ocb_file, permitted_classes: [Date])
      @shows.merge!(ocb_data["events"] || {}) if ocb_data
    end

    # Load historical OCB data
    ocb_historical_files = Dir.glob("db/ocb_historical_events_*.yml")
    ocb_historical_files.each do |file|
      next unless File.exist?(file)
      historical_data = YAML.load_file(file, permitted_classes: [Date])
      @shows.merge!(historical_data["events"] || historical_data || {}) if historical_data
    end

    # Load historical WNBF data
    wnbf_historical_files = Dir.glob("db/wnbf_historical_events_*.yml")
    wnbf_historical_files.each do |file|
      next unless File.exist?(file)
      historical_data = YAML.load_file(file, permitted_classes: [Date])
      @shows.merge!(historical_data["events"] || historical_data || {}) if historical_data
    end

    @last_loaded = Time.now
    @shows
  end

  def is_upcoming?(date)
    case date
    when Date
      date >= Date.today
    when "TBA"
      true # TBA dates are considered upcoming
    else
      false
    end
  end

  def is_past?(date)
    case date
    when Date
      date < Date.today
    else
      false
    end
  end

  def most_recent_file(prefix)
    pattern = "db/#{prefix}_*.yml"
    files = Dir.glob(pattern)
    return nil if files.empty?
    
    # Sort by date in filename and take the most recent
    files.sort_by { |f| extract_date_from_filename(f) }.last
  end

  def extract_date_from_filename(filename)
    # Extract date from filename like "db/wnbf_events_2024-03-25.yml"
    match = filename.match(/(\d{4}-\d{2}-\d{2})/)
    return Date.new(1900, 1, 1) unless match
    
    Date.parse(match[1])
  rescue
    Date.new(1900, 1, 1)
  end

  def most_recent_file_date
    all_files = Dir.glob("db/*_events_*.yml") + Dir.glob("db/*_historical_events_*.yml")
    
    dates = all_files.map do |file|
      File.mtime(file) if File.exist?(file)
    end.compact
    
    dates.max
  end

  def sort_key_for_date(date)
    case date
    when Date
      date
    when "TBA"
      Date.new(2099, 12, 31) # Sort TBA dates to the end
    else
      Date.new(2099, 12, 31)
    end
  end
end
