class Position < ApplicationRecord
  
  #This contains the time and position-data
  #It can be expanded to include additional information like speed
  
  #Most importantly, it can be sorted by position, time, and in ways other than by trip
  #This allows visibility of business peak-times and regional market-penetration  
  
  belongs_to :trip
  
  validates :timestamp, uniqueness: {scope: :trip_id}
end
