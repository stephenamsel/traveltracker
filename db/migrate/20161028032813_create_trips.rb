class CreateTrips < ActiveRecord::Migration[5.0]
  def change
    create_table :trips do |t|

      t.float :distance
      t.timestamps
    end
  end
end
