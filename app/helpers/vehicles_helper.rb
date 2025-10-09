module VehiclesHelper
  def vehicle_sort_options
    [
      ['Registration Number', 'registration_number'],
      ['Make & Model', 'vehicle_model'],
      ['Status', 'status'],
      ['Date Added', 'created_at']
    ]
  end
end
