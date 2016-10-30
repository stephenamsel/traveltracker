

class Trip < ApplicationRecord
  require 'csv'
  require 'open-uri'
  has_many :positions, dependent: :destroy  
  
  #validates :distance, presence: true
  #Validation is done through controller because multiple saves are required to get the distance
  #It's a bit ugly, but enables market-analysis (See below)
  
  def import_csv(csvfile)
    
    csv = CSV.parse(csvfile.read)
    #The test-files were semicolon-delimited, not really CSV. Adjusting for that.
    
    if (csv[0].length == 1) then csv = csv.collect{|i| i[0].split(";")} end
    
    #Strictly speaking, this could be handled by a serialized text-element, but
    #having the times and locations of rentals directly accessible can be very useful for market-analysis.
    #This is why the positions, the product-usage data, are kept in their own table
    
    csv.each do |row|
      self.positions.create(timestamp: Time.at(row[0].to_i), latitude: row[1].to_f, longitude: row[2].to_f)
    end
    
  end
  
  def get_google_data #Get total distance from Google Maps API    
    #arrange datapoints chonologically to build trip
    #doing this here rather than at input to allow for additional data available after oriignal upload
      datapoints = self.positions.sort{|a, b| a.timestamp.to_i <=> b.timestamp.to_i}
      
      #While it is usually preferable to make the minimum number of requests, Google charges by the matrix-element so
      #it is least expensive to retrieve 1x1 matrices containing only the desired distances
      
      #Build request parameters and set up request-loop
      #API documentation at https://developers.google.com/maps/documentation/distance-matrix/intro
      
      request_url = 'https://maps.googleapis.com/maps/api/distancematrix/json?'
      request_key = '&key=AIzaSyBe2zocWsImltBocK1xD2eEtKX-BYwH9gE' #This project's Google Maps JS API key
      distance = 0    
      
      datapoints.each_with_index do |destination, index|
        #It is computationally faster to use 'datapoints.length.times do', shift and datapoints[0], but this way
        #the array is preserved to allow other data to be calculated outside of the request-loop
        if index == 0 then next end
        
        origin = datapoints[index - 1]
        origin_string = '&origins=' + origin.latitude.to_s + ',' + origin.longitude.to_s
        destination_string = '&destinations=' + destination.latitude.to_s + ',' + destination.longitude.to_s      
        request_string = request_url + origin_string + destination_string + request_key
        
        response = open(request_string).read
        data = ActiveSupport::JSON.decode(response)
        distance += data['rows'][0]['elements'][0]['distance']['value'].to_f 
        
      end
      self.update_attribute(:distance, distance.to_f) #distance in m
  end
end
