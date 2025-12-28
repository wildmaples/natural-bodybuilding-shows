module Api
  module V1
    class EventsController < ApplicationController
      skip_forgery_protection

      def index
        events = Event.upcoming.order(:date)
        events = events.where(federation: params[:federation]) if params[:federation].present?
        events = events.by_location(params[:location]) if params[:location].present?

        render json: events.as_json(only: [ :id, :name, :date, :location, :state, :url, :federation ])
      end

      def show
        event = Event.find(params[:id])
        render json: event.as_json(only: [ :id, :name, :date, :location, :state, :url, :federation, :divisions ])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Event not found" }, status: :not_found
      end
    end
  end
end
