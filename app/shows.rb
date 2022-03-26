require 'yaml'

class Shows
  def initialize
    @shows = nil
  end

  def get
    wnbf = YAML.load_file("db/wnbf_events_2022-03-25.yaml", permitted_classes: [Date])["events"]
    ocb = YAML.load_file("db/ocb_amateur_events_2022-03-25.yaml", permitted_classes: [Date])["events"]
    @shows ||= wnbf.merge!(ocb)
  end
end
