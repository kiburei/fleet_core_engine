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
end
