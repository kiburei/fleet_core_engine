module FleetProvidersHelper
  def fleet_provider_sort_options
    [
      ['Name', 'name'],
      ['Registration Number', 'registration_number'],
      ['License Status', 'license_status'],
      ['Date Added', 'created_at']
    ]
  end
end
