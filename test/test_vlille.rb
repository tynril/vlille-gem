require 'test/unit'
require 'webmock/test_unit'
require 'vlille'

# Tests for the VLille system.
class VLilleTest < Test::Unit::TestCase

	# Test if the parsing of information works.
	def test_parsing
		# Setting up mock responses.
		stub_request(:any, VLille::BaseAddress + VLille::ServiceAddress) \
			.to_return(status: 200, body: File.new('./test/stubs/xml-stations.xml'))
		stub_request(:any, VLille::BaseAddress + VLilleStation::ServiceAddress) \
			.with(query: {'borne' => '1'}) \
			.to_return(status: 200, body: File.new('./test/stubs/xml-station-1.xml'))
		stub_request(:any, VLille::BaseAddress + VLilleStation::ServiceAddress) \
			.with(query: {'borne' => '10'}) \
			.to_return(status: 200, body: File.new('./test/stubs/xml-station-10.xml'))

		# Initialize a new VLille service and ensure its emptiness.
		vl = VLille.new
		assert_equal vl.stations.size, 0
		assert_nil vl.center_lat
		assert_nil vl.center_lng
		assert_nil vl.zoom_level

		# Load its content.
		vl.load(true)

		# Ensure we have the data we expect.
		assert_equal vl.center_lat, 50.675
		assert_equal vl.center_lng, 3.1
		assert_equal vl.zoom_level, 12
		assert_equal vl.stations.size, 2

		# Ensure the stations have correct data as well.
		station1 = vl.find_station(1)
		assert_equal station1.id, 1
		assert_equal station1.name, "Lille Metropole"
		assert_equal station1.lat, 50.6419
		assert_equal station1.lng, 3.07599
		assert_equal station1.address, "LMCU RUE DU BALLON "
		assert_equal station1.status, :working
		assert_equal station1.bikes, 6
		assert_equal station1.attachs, 30
		assert_equal station1.payment, :available
		assert_equal station1.last_update, Time.now.to_i - 2

		station10 = vl.find_station(10)
		assert_equal station10.id, 10
		assert_equal station10.name, "Rihour"
		assert_equal station10.lat, 50.6359
		assert_equal station10.lng, 3.06247
		assert_equal station10.address, "ANGLE PLACE RIHOUR RUE JEAN ROISIN "
		assert_equal station10.status, :working
		assert_equal station10.bikes, 12
		assert_equal station10.attachs, 20
		assert_equal station10.payment, :unavailable
		assert_equal station10.last_update, Time.now.to_i - ((6 * 60 * 60) + (4 * 60) + 2)
	end

	# Ensure that connectivity is possible.
	def test_connectivity
		# Allow real requests.
		WebMock.allow_net_connect!

		# Initialize a new VLille service and load its status.
		vl = VLille.new
		vl.load()

		# Ensure there's something in the result.
		assert_not_nil vl.center_lat
		assert_not_nil vl.center_lng
		assert_not_nil vl.zoom_level
		assert vl.stations.size > 0

		# Load a station to check for emptiness.
		station = vl.stations[0]
		assert_not_nil station.id
		assert_not_nil station.name
		assert_not_nil station.lat
		assert_not_nil station.lng
		assert_nil station.address
		assert_nil station.status
		assert_nil station.bikes
		assert_nil station.attachs
		assert_nil station.payment
		assert_nil station.last_update

		# Load the station and test we have some data now.
		station.load
		assert_not_nil station.address
		assert_not_nil station.status
		assert_not_nil station.bikes
		assert_not_nil station.attachs
		assert_not_nil station.payment
		assert_not_nil station.last_update

		# Disallow real requests.
		WebMock.disable_net_connect!
	end
end
