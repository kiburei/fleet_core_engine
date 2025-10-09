module DriversHelper
  def driver_sort_options
    [
      ['Name', 'name'],
      ['License Number', 'license_number'],
      ['Join Date', 'created_at'],
      ['License Status', 'license_status']
    ]
  end
end
