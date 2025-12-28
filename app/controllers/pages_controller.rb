class PagesController < ApplicationController
  def about
  end

  def health
    render json: {
      status: "ok",
      last_updated: Event.maximum(:updated_at),
      event_count: Event.count,
      data_stale: ScraperManager.new.data_needs_refresh?
    }
  end
end
