require 'active_record'

class CreateInfos < ActiveRecord::Migration

  def change
    create_table :infos do |t|
      t.integer :user_id, null: false
      t.string :name, limit: 16, null: false
      t.date :birthday, null: false
      t.integer :sex, limit: 8, null: false
      t.string :img_url, limit: 128, null: false
    end
  end

end