class User < ApplicationRecord
  rolify before_add: :before_add_method
  after_create :assign_default_role
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  belongs_to :fleet_provider, optional: true

  def before_add_method(role)
    # Custom logic before adding a role
    puts "Before adding role: #{role.name}"
  end

  def assign_default_role
    if self.roles.blank?
      self.add_role(:user)
    end
  end

  def full_name
    ([ first_name, last_name ] - [ "" ]).compact.join(" ")
  end

  def admin?
    has_role?(:admin)
  end

  def fleet_provider_admin?
    has_role?(:fleet_provider_admin)
  end

  def fleet_provider_manager?
    has_role?(:fleet_provider_manager)
  end

  def fleet_provider_owner?
    has_role?(:fleet_provider_owner)
  end

  def fleet_provider_user?
    has_role?(:fleet_provider_user)
  end

  def fleet_provider_driver?
    has_role?(:fleet_provider_driver)
  end
end
