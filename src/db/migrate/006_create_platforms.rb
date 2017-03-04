require 'active_record'

class CreatePlatforms < ActiveRecord::Migration

  def change
    create_table :platforms do |t|
      t.integer :user_id, null: false
      t.string :open_id, null: false
      t.string :platform_type, limit: 16
    end
  end

end