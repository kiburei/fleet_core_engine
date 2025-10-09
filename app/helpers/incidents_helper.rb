module IncidentsHelper
  def incident_sort_options
    [
      ['Incident Date', 'incident_date'],
      ['Type', 'incident_type'],
      ['Location', 'location'],
      ['Damage Cost', 'damage_cost'],
      ['Date Created', 'created_at']
    ]
  end
end
