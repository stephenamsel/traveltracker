module Trip
  has_many :positions
  
  before_save :get_google_distance
  
  valiates :distance, presence: true
  
  def import_csv(file)
    csv_text = File.read(csvfile)
    csv = CSV.parse(csv_text)
    
    csv.each do |row|
      
      self.positions.create(timestamp: Time.at(row[0]), latitude: row[1], longitude: row[2])
    end
  end
  
  def get_google_data #Get total distance from Google Maps API    
    #arrange datapoints chonologically to build trip
    #doing this here rather than at input to allow for additional data available after oriignal upload
    
    datapoints = self.positions.sort{|a, b| a.timestamp.to_i <=> b.timestamp.to_i}
    
    #build request parameters
    request_string = 'https://maps.googleapis.com/maps/api/distancematrix/json?'
    
    origin = datapoints.shift
    request_string += '&origins=' + origin.latitude + ',' + origin.longitude
    request_string += '&destinations=' + datapoints.collect{|a| a.latitude + '%2C' + a.longitude}.join('%7C')
    request_string += '&key=AIzaSyBe2zocWsImltBocK1xD2eEtKX-BYwH9gE' #This project's Google Maps JS API key    
    
    #Use Google Maps API
    url = URI.parse(request_string)
    request = Net::HTTP::Get.new(url.to_s)
    response = Net::HTTP.start(url.host, url.port) {|http| http.request(request)}
    
    ActiveSupport::JSON.decode(response.body)    
  end
  
  def get_google_distance
    data = get_google_data
    self.distance = data['rows'].collect{|i| i['elements']['distance']['value']}.sum #distance in km
    
  end
end
