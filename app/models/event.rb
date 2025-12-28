class Event < ApplicationRecord
  FEDERATIONS = %w[OCB WNBF].freeze

  validates :name, presence: true
  validates :federation, presence: true, inclusion: { in: FEDERATIONS }

  scope :upcoming, -> { where("date >= ? OR date IS NULL", Date.current).order(:date) }
  scope :past, -> { where("date < ?", Date.current).order(date: :desc) }
  scope :by_federation, ->(federation) { where(federation: federation) if federation.present? }
  scope :by_location, ->(location) { where("location LIKE ? OR state LIKE ?", "%#{location}%", "%#{location}%") if location.present? }
  scope :by_name, ->(name) { where("name LIKE ?", "%#{name}%") if name.present? }
  scope :by_date_range, ->(from, to) {
    scope = all
    scope = scope.where("date >= ?", from) if from.present?
    scope = scope.where("date <= ?", to) if to.present?
    scope
  }

  def upcoming?
    date.nil? || date >= Date.current
  end

  def past?
    date.present? && date < Date.current
  end

  def formatted_date
    return "TBA" if date.nil?
    date.strftime("%b %d, %Y")
  end
end
