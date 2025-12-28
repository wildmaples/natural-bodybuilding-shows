class EventsController < ApplicationController
  def index
    @upcoming_events = filter_events(Event.upcoming)
    @past_events = filter_events(Event.past)

    @upcoming_count = @upcoming_events.count
    @past_count = @past_events.count
    @last_updated = Event.maximum(:updated_at)
    @data_freshness = ScraperManager.new.data_freshness
  end

  private

  def filter_events(scope)
    scope = scope.by_federation(params[:federation]) if params[:federation].present?
    scope = scope.by_name(params[:name]) if params[:name].present?
    scope = scope.by_location(params[:location]) if params[:location].present?
    scope = scope.by_date_range(params[:date_from], params[:date_to])
    scope
  end
end
