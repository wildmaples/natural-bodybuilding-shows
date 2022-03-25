require 'yaml'

class Shows
  def initialize
    @shows = nil
  end

  def get
    @shows ||= YAML.load_file("wnbf_events_2022.yaml", permitted_classes: [Date])
  end
end
