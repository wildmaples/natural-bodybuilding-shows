class CreateEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :events do |t|
      t.string :name, null: false
      t.date :date
      t.string :location
      t.string :state
      t.string :url
      t.string :federation, null: false
      t.date :archived_on
      t.text :divisions

      t.timestamps
    end

    add_index :events, %i[name date federation], unique: true, name: "index_events_uniqueness"
    add_index :events, :date
    add_index :events, :federation
  end
end
