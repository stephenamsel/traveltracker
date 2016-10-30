class CreatePositions < ActiveRecord::Migration[5.0]
  def change
    create_table :positions do |t|
      t.float :latitude
      t.float :longitude
      t.datetime :timestamp
      t.references :trip

      t.timestamps
    end
  end
end
