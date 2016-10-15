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
		var height,
			gender,
			birthYear,
			activityClass;

		function initialize() {
			var profile = UserProfile.getProfile();
			if (profile) {
				height = profile.height;
				gender = profile.gender;
				birthYear = profile.birthYear;
				activityClass =  profile.activityClass;
			}
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
			:searchTimeoutLowPriority => 10,    // Timeout in 25s
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

	function onMessage(msg) {
		// Parse the payload
		var payload = msg.getPayload();
	}
}