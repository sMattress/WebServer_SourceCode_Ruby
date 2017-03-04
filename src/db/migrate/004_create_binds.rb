require 'active_record'

class CreateBinds <ActiveRecord::Migration

  def change
    create_table :binds do |t|
      t.integer :user_id, null: false
      t.integer :device_id, null: false
      t.string :alias, limit: 32
    end
  end

end