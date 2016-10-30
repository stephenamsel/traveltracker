class TripsController < ApplicationController
  before_action :set_trip, only: [:show, :edit, :update, :destroy]

  # GET /trips
  # GET /trips.json
  def index
    @trips = Trip.all
  end

  # GET /trips/1
  # GET /trips/1.json
  def show
    redirect_to trips_path
  end

  # GET /trips/new
  def new
    @trip = Trip.new
  end

  # GET /trips/1/edit
  def edit
  end

  # POST /trips
  # POST /trips.json
  def create
    @trip = Trip.new#(trip_params)    

    respond_to do |format|
      if @trip.save && get_distance
        #The trip must be saved to create the position-records, so they are being added here
        
        format.html { redirect_to trips_path, notice: 'Trip was successfully created.' }
        format.json { render :show, status: :created, location: @trip }
      else
        format.html { render :new }
        format.json { render json: @trip.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /trips/1
  # PATCH/PUT /trips/1.json
  def update
    respond_to do |format|
      if @trip.update(trip_params) && get_distance
        #It is assumed that additionaly position-data is uploaded.
        #If not, then we should check whether that has happened before running get_distance as this involved Google API calls
        format.html { redirect_to @trip, notice: 'Trip was successfully updated.' }
        format.json { render :show, status: :ok, location: @trip }
      else
        format.html { render :edit }
        format.json { render json: @trip.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /trips/1
  # DELETE /trips/1.json
  def destroy
    @trip.destroy
    respond_to do |format|
      format.html { redirect_to @trip, notice: 'Trip was successfully deleted.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_trip
      @trip = Trip.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def trip_params
      params.fetch(:trip, {})
    end
    
    def get_distance
      if params['trip'] && params['trip']['uploadfile'] then
        begin
          @trip.import_csv(params['trip']['uploadfile'])
          @trip.get_google_data
        #rescue
        #  @trip.errors[:base] << "File Format error."
        #  return false
        end
        return true
        #The trip must be re-saved with the distance
      elsif !@trip.distance        
        @trip.destroy
        @trip.errors[:base] << "Distance could not be calculated! Upload data-file."
        return false
        #but should not be kept if the distance could not be recorded
        #This would be done with a validation, but then the original saving, needed to get the positions associated properly, would fail
        
      else #It's an update not involving the distance
        #With nothing else being tracked yet, that means no changes were made, which is probably an error
        @trip.errors[:base] << "No changes made. Did you mean to do something?"
        return true
      end
    end
end
