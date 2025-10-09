module MaintenancesHelper
  def maintenance_sort_options
    [
      ['Maintenance Date', 'maintenance_date'],
      ['Type', 'maintenance_type'],
      ['Status', 'status'],
      ['Cost', 'maintenance_cost'],
      ['Date Created', 'created_at']
    ]
  end
end
