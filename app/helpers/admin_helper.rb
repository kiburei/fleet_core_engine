module AdminHelper
  def status_badge_class(status)
    case status.to_s
    when 'pending'
      'bg-yellow-100 text-yellow-800'
    when 'assigned'
      'bg-blue-100 text-blue-800'
    when 'picked_up'
      'bg-purple-100 text-purple-800'
    when 'in_transit'
      'bg-indigo-100 text-indigo-800'
    when 'delivered'
      'bg-green-100 text-green-800'
    when 'cancelled'
      'bg-red-100 text-red-800'
    else
      'bg-gray-100 text-gray-800'
    end
  end

  def priority_badge_class(priority)
    case priority.to_s
    when 'high'
      'bg-orange-100 text-orange-800'
    when 'urgent'
      'bg-red-100 text-red-800'
    else
      'bg-gray-100 text-gray-800'
    end
  end

  def driver_status_class(status)
    case status.to_s
    when 'online'
      'bg-green-100 text-green-800'
    when 'offline'
      'bg-gray-100 text-gray-800'
    when 'busy'
      'bg-yellow-100 text-yellow-800'
    else
      'bg-gray-100 text-gray-800'
    end
  end

  def distance_in_words(distance_km)
    return 'N/A' unless distance_km

    if distance_km < 1
      "#{(distance_km * 1000).round(0)}m"
    else
      "#{distance_km.round(1)}km"
    end
  end

  def duration_in_words(minutes)
    return 'N/A' unless minutes

    if minutes < 60
      "#{minutes}min"
    else
      hours = minutes / 60
      remaining_minutes = minutes % 60
      if remaining_minutes > 0
        "#{hours}h #{remaining_minutes}min"
      else
        "#{hours}h"
      end
    end
  end

  def format_currency(amount)
    return '$0.00' unless amount
    "$#{'%.2f' % amount}"
  end

  def delivery_status_options_for_select
    [
      ['All Statuses', ''],
      ['Pending', 'pending'],
      ['Assigned', 'assigned'],
      ['Picked Up', 'picked_up'],
      ['In Transit', 'in_transit'],
      ['Delivered', 'delivered'],
      ['Cancelled', 'cancelled']
    ]
  end

  def priority_options_for_select
    [
      ['All Priorities', ''],
      ['Normal', 'normal'],
      ['High', 'high'],
      ['Urgent', 'urgent']
    ]
  end

  def driver_status_options_for_select
    [
      ['All Statuses', ''],
      ['Online', 'online'],
      ['Offline', 'offline'],
      ['Busy', 'busy']
    ]
  end

  def format_phone_number(phone)
    return 'N/A' unless phone
    # Simple formatting for US numbers
    if phone.match?(/^\d{10}$/)
      phone.gsub(/(\d{3})(\d{3})(\d{4})/, '(\1) \2-\3')
    else
      phone
    end
  end

  def truncate_address(address, length = 50)
    return 'N/A' unless address
    truncate(address, length: length)
  end

  def coordinates_link(latitude, longitude, label = 'View on Map')
    return 'N/A' unless latitude && longitude
    maps_url = "https://www.google.com/maps?q=#{latitude},#{longitude}"
    link_to label, maps_url, target: '_blank', class: 'text-blue-600 hover:text-blue-800 text-sm'
  end

  def delivery_metrics_card(title, value, subtitle = nil, color_class = 'text-gray-900')
    content_tag :div, class: 'bg-white rounded-lg shadow p-6' do
      content_tag(:h3, title, class: 'text-lg font-medium text-gray-900 mb-2') +
      content_tag(:p, value, class: "text-3xl font-bold #{color_class}") +
      (subtitle ? content_tag(:p, subtitle, class: 'text-sm text-gray-500 mt-1') : '')
    end
  end

  def time_range_options_for_select
    [
      ['Today', 'today'],
      ['Yesterday', 'yesterday'],
      ['This Week', 'this_week'],
      ['Last Week', 'last_week'],
      ['This Month', 'this_month'],
      ['Last Month', 'last_month'],
      ['Custom Range', 'custom']
    ]
  end

  def available_drivers_count(fleet_provider = nil)
    scope = Driver.available
    scope = scope.joins(:fleet_provider).where(fleet_providers: { id: fleet_provider.id }) if fleet_provider
    scope.count
  end

  def busy_drivers_count(fleet_provider = nil)
    scope = Driver.busy
    scope = scope.joins(:fleet_provider).where(fleet_providers: { id: fleet_provider.id }) if fleet_provider
    scope.count
  end

  def pending_deliveries_count(fleet_provider = nil)
    scope = DeliveryRequest.pending
    scope = scope.where(fleet_provider: fleet_provider) if fleet_provider
    scope.count
  end

  def today_deliveries_count(fleet_provider = nil)
    scope = DeliveryRequest.where(created_at: Date.current.all_day)
    scope = scope.where(fleet_provider: fleet_provider) if fleet_provider
    scope.count
  end

  def completion_rate(fleet_provider = nil, period = 30.days)
    scope = DeliveryRequest.where(created_at: period.ago..Time.current)
    scope = scope.where(fleet_provider: fleet_provider) if fleet_provider
    
    total = scope.count
    return 0 if total.zero?
    
    completed = scope.delivered.count
    ((completed.to_f / total) * 100).round(1)
  end
end