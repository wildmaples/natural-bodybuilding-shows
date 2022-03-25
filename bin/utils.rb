require 'date'

class Utils
  def self.convert_date(date)
    # Only use the first date if there is a range given
    if date.include?("-")
      idx = date.index("-") - 1
      date = date[..idx]
    end

    case date
    when "TBA"
      date
    when "2023"
      Date.new(2023)
    else
      if date.include?("/")
        date_components = Date._strptime(date, '%m/%d/%Y')
        if date_components.nil?
          warn("Invalid input '#{date}' for '%m/%d/%Y' format.")
          "TBA"
        else
          Date.new(date_components[:year], date_components[:mon], date_components[:mday])
        end
      else
        Date.parse(date)
      end
    end
  end

  def self.store_as_yaml(file, data)
    store = YAML::Store.new(file)
    store.transaction do
      store["validated"] = false
      store["last_updated"] = Date.today
      store["events"] = data
    end
  end
end
