class CreateFleetProviderUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :fleet_provider_users do |t|
      t.references :user, null: false, foreign_key: true
      t.references :fleet_provider, null: false, foreign_key: true

      t.timestamps
    end
  end
end
