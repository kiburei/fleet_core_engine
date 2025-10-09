module TripsHelper
  def trip_sort_options
    [
      ['Origin', 'origin'],
      ['Destination', 'destination'],
      ['Status', 'status'],
      ['Departure Time', 'departure_time'],
      ['Date Created', 'created_at']
    ]
  end
end
