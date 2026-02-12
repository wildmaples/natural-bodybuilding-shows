Rails.application.config.after_initialize do
  if Rails.env.production? && ENV["SOLID_QUEUE_IN_PUMA"]
    ScrapeEventsJob.perform_later
  end
end
