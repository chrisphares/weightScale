using Toybox.Ant as Ant;
using Toybox.Time as Time;
using Toybox.WatchUi as Ui;
using Toybox.UserProfile as UserProfile;

class weightScaleSensor extends Ant.GenericChannel {
	const DEVICE_TYPE = 119;
	const PERIOD = 8192;

	hidden var chanAssign;

	var searching,
		deviceCfg,
		userData;

	class User {
		var profileID,
			height,
			gender,
			birthYear,
			activityClass,
			hydration,
			bodyFat;

		function initialize() {
			var profile = UserProfile.getProfile();
			if (profile) {
				height = profile.height;
				gender = profile.gender;
				birthYear = profile.birthYear;
				activityClass = profile.activityClass;
			}
		}
	}

	class userProfilePage {
		static const PAGE_NUMBER = 0x3A;
		//userProfileID - 2 bytes
		//capabilities - 1 byte
		//reserved 1 byte: 0xFF
		//age - bits 0-6
		//gender - bit 7
		//height
		//descriptoive byte : bit 0-2 - activity level / bit 7 - Athelte setting
	}

	class bodyCompositionPage {
		static const PAGE_NUMBER = 0x02;

		function parse(payload, userData) {
			userData.hydration = parseHydration(payload);
			userData.bodyFat = parseBodyFat(payload);
		}

		hidden function parseHydration(payload) {
			return (payload[4] + payload[5]); //not quite yet
		}

		hidden function parseBosyFat(payload) {
			return (payload[6] + payload[7]); //not quite yet
		}
	}

	class metabolicPage {
		static const PAGE_NUMBER = 0x03;

		function parse(payload, userData) {
			userData.hydration = parseActiveRate(payload);
			userData.bodyFat = parseBasalRate(payload);
		}

		hidden function parseActiveRate(payload) {
			return (payload[4] + payload[5]); //not quite yet (*4)
		}

		hidden function parseBasalRate(payload) {
			return (payload[6] + payload[7]); //not quite yet ( *4)
		}
	}

	class bodyMassPage {
		static const PAGE_NUMBER = 0x04;

		function parse(payload, userData) {
			userData.hydration = parseMuscleMass(payload);
			userData.bodyFat = parseBoneMass(payload);
		}

		hidden function parseMuscleMass(payload) {
			return (payload[4] + payload[5]); //not quite yet
		}

		hidden function parseBoneMass(payload) {
			return (payload[6]); //not quite yet
		}
	}

	function initialize() {
		// Get the channel
		chanAssign = new Ant.ChannelAssignment(Ant.CHANNEL_TYPE_RX_NOT_TX, Ant.NETWORK_PLUS);
		GenericChannel.initialize(method(:onMessage), chanAssign);

		// Set the configuration
		deviceCfg = new Ant.DeviceConfig( {
			:deviceNumber => 0,                 // Wildcard our search
			:deviceType => DEVICE_TYPE,
			:transmissionType => 0,
			:messagePeriod => PERIOD,
			:radioFrequency => 57,              // Ant+ Frequency
			:searchTimeoutLowPriority => 4,    // Timeout in 2.5s increment
			:searchThreshold => 0} );           // Pair to all transmitting sensors
		GenericChannel.setDeviceConfig(deviceCfg);

		searching = true;
    }

	function open() {
	// Open the channel
		GenericChannel.open();

		userData = new User();
		searching = true;
	}

	function closeSensor() {
		GenericChannel.close();
	}

	function sendUserProfile() {
		if (!searching) { //this may fail
			var payload = new [8];

			//see userdata page class
			payload[0] = ;
			payload[1] = ;
			payload[2] = ;
			payload[3] = ;
			payload[4] = ;
			payload[5] = ;
			payload[6] = ;
			payload[7] = ;


			// Form and send the message
			var message = new Ant.Message();
			message.setPayload(payload);
			GenericChannel.sendAcknowledge(message);
		}
	}

	function onMessage(msg) {
		// Parse the payload
		var payload = msg.getPayload();

		//select case for which page was recieved :: date = new <page> class :: <page>.parse
	}
}