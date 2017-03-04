require 'active_record'

class CreateDevices < ActiveRecord::Migration

  def change
    create_table :devices do |t|
      t.string :name, limit: 32, null: false
    end
  end

end