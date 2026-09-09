class CreateTimePeriods < ActiveRecord::Migration[8.1]
  def change
    create_table :time_periods do |t|
      t.string :name, null: false
      t.integer :position, null: false

      t.timestamps
    end
  end
end
