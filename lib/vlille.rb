require 'httparty'
require 'multi_xml'

# Container for the data about the VLille bike-sharing system.
class VLille
	# Base address for the VLille service.
	BaseAddress = 'http://www.vlille.fr'

	# Service address for the list of stations.
	ServiceAddress = '/stations/xml-stations.aspx'

	# Include the HTTParty module to process the queries.
	include HTTParty
	base_uri BaseAddress

	# List of all the VLille station. Empty before <tt>load</tt> gets called.
	attr_reader :stations

	# Position and zoom level at which the map should be positioned to encompass
	# the entire VLille network. Empty before <tt>load</tt> gets called.
	attr_reader :center_lat, :center_lng, :zoom_level

	# Initialize an empty VLille container. load must be called to fill it.
	def initialize
		reset
	end

	# Loads (or re-loads) all data from the VLille service.
	def load(load_details = false)
		reset

		# Switching the parser to rexml, which handles the encoding error in the
		# result.
		MultiXml.parser = :rexml

		# Performing the query to the VLille service.
		markers = self.class.post(
			ServiceAddress,
			{ format: :xml }
		).parsed_response['markers']

		# Parsing global results.
		@center_lat = markers['center_lat'].to_f
		@center_lng = markers['center_lng'].to_f
		@zoom_level = markers['zoom_level'].to_f

		# Instanciating each station.
		markers['marker'].each do |marker|
			station = VLilleStation.new marker
			if load_details
				station.load
			end
			@stations << station
		end
	end

	# Find a station by its identifier.
	def find_station(id)
		@stations.find do |station|
			station.id == id
		end
	end

	# Resets the content of the container, clearing all data.
	def reset
		@stations = []
		@center_lat = nil
		@center_lng = nil
		@zoom_level = nil
	end
end

# Represents a single station in the VLille system.
class VLilleStation
	# Address of the station details service.
	ServiceAddress = '/stations/xml-station.aspx'

	# Include the HTTParty module to process the queries.
	include HTTParty
	base_uri VLille::BaseAddress

	# Identifier of the station.
	attr_reader :id

	# Name of the station.
	attr_reader :name

	# Position of the station.
	attr_reader :lat, :lng

	# Address of the station.
	attr_reader :address

	# Current status of the station. Can be :unknown, :working or :not_working.
	attr_reader :status

	# Number of availables bikes at the station.
	attr_reader :bikes

	# Number of free attachs at the station.
	attr_reader :attachs

	# Availability of a payment terminal at the station. Can be :unknown,
	# :available or :unavailable.
	attr_reader :payment

	# Timestamp of the last time data about this station were updated.
	attr_reader :last_update

	# Initialize a station from a marker.
	def initialize(marker)
		@id = marker['id'].to_i
		@name = marker['name']
		@lat = marker['lat'].to_f
		@lng = marker['lng'].to_f

		@address = nil
		@status = nil
		@bikes = nil
		@attachs = nil
		@payment = nil
		@last_update = nil
	end

	# Load the data about this station from the VLille service.
	def load
		station = self.class.post(
			ServiceAddress,
			{ format: :xml, method: :get, query: {borne: @id} }
		).parsed_response['station']

		@address = station['adress']
		@bikes = station['bikes'].to_i
		@attachs = station['attachs'].to_i

		update_regexp = /(?:(?:(?<hours>\d+) heure\(s\) )?(?<minutes>\d+) minute\(s\) )?(?<seconds>\d+) secondes/
		lastupd_match = update_regexp.match(station['lastupd'])
		if lastupd_match
			secondsAgo = (lastupd_match[:hours].to_i * 60 * 60) + (lastupd_match[:minutes].to_i * 60) + lastupd_match[:seconds].to_i
			@last_update = Time.now.to_i - secondsAgo
		else
			@last_update = -1
		end

		if station['status'].to_i == 0
			@status = :working
		else
			@status = :not_working
		end

		if station['paiement'] == 'AVEC_TPE'
			@payment = :available
		else
			@payment = :unavailable
		end
	end
end
