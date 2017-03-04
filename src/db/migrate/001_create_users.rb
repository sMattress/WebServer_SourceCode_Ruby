require 'active_record'

class CreateUsers < ActiveRecord::Migration

  def change
    create_table :users do |t|
      t.string :account, limit: 12, null: false
      t.string :password, limit: 32, null: false
    end
  end

end
