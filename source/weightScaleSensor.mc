using Toybox.Ant as Ant;
using Toybox.Lang as Lang;
using Toybox.Time as Time;
using Toybox.System as Sys;
using Toybox.WatchUi as Ui;
using Toybox.UserProfile as UserProfile;
using Toybox.Time.Gregorian as Calendar;

class weightScaleSensor extends Ant.GenericChannel {

	hidden var chanAssign;

	var searching,
		deviceCfg,
		userData,
		bodyWeightData,
		bodyCompData,
		metabolicData,
		bodyMassData;

	class userInfo {
		var profileID,
			scaleProfileID = 0,
			height,
			gender,
			age,
			activityClass,
			bodyWeight,
			hydration,
			percentFat,
			activeRate,
			basalRate,
			muscleMass,
			boneMass;

		function initialize() {
			var profile = UserProfile.getProfile();
			if (profile) {
				height = profile.height;
				gender = profile.gender;
				activityClass = profile.activityClass;

				var now = Time.now();
				var info = Calendar.info(now, Time.FORMAT_SHORT);
				age = info.year - profile.birthYear;
			}

			var device = Sys.getDeviceSettings();
			if (device) {
				profileID = device.partNumber;
				profileID = ((profileID.hashCode() >> 4) & 0xFFFF);
			}
		}
	}

	class bodyWeightPage {
		static const PAGE_NUMBER = 0x01;

		function parse(payload, userData) {
			userData.bodyWeight = parseBodyWeight(payload);
			Sys.println(userData.bodyWeight);
		}

		hidden function parseBodyWeight(payload) {
			if (payload[6] == 0xFE && payload[7] == 0xFF) {
				return 0;
			}
			else if (payload[6] == 0xFF && payload[7] == 0xFF) {
				return null;
			}
			else {
				var kilo = payload[6] + ((payload[7] & 0xFF) << 8);
				kilo = kilo.toDouble() / 100;
				kilo = Lang.format("$1$", [kilo.format("%01.2d")]);
				return kilo;
			}
		}
	}

	class bodyCompositionPage {
		static const PAGE_NUMBER = 0x02;

		function parse(payload, userData) {
			userData.hydration = parseHydration(payload);
			userData.percentFat = parsePercentFat(payload);
			Sys.println("body comp page");
		}

		hidden function parseHydration(payload) {
			return (payload[4] + payload[5]); //not quite yet
		}

		hidden function parsePercentFat(payload) {
			return (payload[6] + payload[7]); //not quite yet
		}
	}

	class metabolicPage {
		static const PAGE_NUMBER = 0x03;

		function parse(payload, userData) {
			userData.activeRate = parseActiveRate(payload);
			userData.basalRate = parseBasalRate(payload);
			Sys.println("met page");
		}

		hidden function parseActiveRate(payload) {
			return ((payload[4] | ((payload[5] & 0x0F) << 8))); //needs validation
		}

		hidden function parseBasalRate(payload) {
			return (payload[6] + payload[7]); //not quite yet ( *4)
		}
	}

	class bodyMassPage {
		static const PAGE_NUMBER = 0x04;

		function parse(payload, userData) {
			userData.muscleMass = parseMuscleMass(payload);
			userData.boneMass = parseBoneMass(payload);
			Sys.println("body mass page");
		}

		hidden function parseMuscleMass(payload) {
			return (payload[4] + payload[5]); //not quite yet
		}

		hidden function parseBoneMass(payload) {
			return (payload[6] + payload[7]); //not quite yet
		}
	}

	class commonManInfoPage {
		static const PAGE_NUMBER = 0x50;

		function parse(payload, userData) {
			Sys.println("man info page");
		}

		hidden function parseManID(payload) {
			return (payload[4] + ((payload[5] & 0xFF) << 8));
		}

		hidden function parseModelNumber(payload) {
			return (payload[6] + ((payload[7] & 0xFF) << 8));
		}
	}

	class commonProductPage {
		static const PAGE_NUMBER = 0x51;

		function parse(payload, userData) {
			Sys.println("product info page");
			//var temp = setDevCfg();
			Sys.println(parseProfileID());
		}

		hidden function parseProfileID() {
			//var MSB = (deviceCfg[:deviceNumber] & 0xFF);
			//var LSB = ((deviceCfg[:deviceNumber] >> 8) & 0xFF);
		}
	}

	class tanitaDataPage {
		static const PAGE_NUMBER = 0xF1;

		function parse(payload, userData) {
			Sys.println("Tanita page");
			Sys.println(parseFirst(payload));
			Sys.println(parseSecond(payload));
		}

		hidden function parseFirst(payload) {
			var MSB = (payload[4] & 0xFF);
			var LSB = (payload[3] & 0xFF);
			return (MSB + ":" + LSB);
		}

		hidden function parseSecond(payload) {
			var MSB = (payload[7] & 0xFF);
			var LSB = (payload[6] & 0xFF);
			return (MSB + ":" + LSB);
		}
	}

	function initialize() {
		// Get the channel
		chanAssign = new Ant.ChannelAssignment(Ant.CHANNEL_TYPE_RX_NOT_TX, Ant.NETWORK_PLUS);//slave
		GenericChannel.initialize(method(:onMessage), chanAssign);

		// Set the configuration
		deviceCfg = new Ant.DeviceConfig({
			:deviceNumber => 0,					// Wildcard our search
			:deviceType => 119,					// 119 (0x77) weight scale type
			:transmissionType => 0,				// 0 for pairing
			:messagePeriod => 8192,				// 4Hz default
			:radioFrequency => 57,				// 57 (0x39) Ant+ Frequency
			:searchTimeoutLowPriority => 8,		// Timeout in 2.5s increment
			:searchThreshold => 0});			// Pair to all transmitting sensors
		GenericChannel.setDeviceConfig(deviceCfg);

		userData = new userInfo();
    }

	function open() {
	// Open the channel
		GenericChannel.open();

		userData = new userInfo();
		searching = true;
		Ui.requestUpdate();
		Sys.println("open channel");
	}

	function closeSensor() {
		GenericChannel.close();
		searching = false;
		Ui.requestUpdate();
		Sys.println("close channel");
	}

	function onMessage(msg) {
		// Parse the payload
		var payload = msg.getPayload();
		var payloadString = msg.deviceNumber;
		for (var i = 0; (i < msg.length && i < 8); i++) {
			payloadString = payloadString + ":" + payload[i];
		}
		Sys.println(payloadString);

		if (Ant.MSG_ID_BROADCAST_DATA == msg.messageId) {
			if (userData.scaleProfileID == 0) {
				deviceCfg = GenericChannel.getDeviceConfig(); // for purposes of storing device ID
				userData.scaleProfileID = msg.deviceNumber;
				var LSB = (userData.scaleProfileID & 0xFF); // Byte 1 & 2: user profile ID
				var MSB = ((userData.scaleProfileID >> 8) & 0xFF);
				Sys.println("setting " + MSB + ":" + LSB);
			}
			else {
				var dataPage = null;

				if (bodyWeightPage.PAGE_NUMBER == (payload[0].toNumber() & 0xFF)) {
					dataPage = new bodyWeightPage();
					if (payload[1] == 0xFF && payload[2] == 0xFF) { //no scale profile ID
						sendUserProfile();
					}
					dataPage.parse(payload, userData);
					dataPage = null;
					Ui.requestUpdate();
				}
				else if (bodyCompositionPage.PAGE_NUMBER == (payload[0].toNumber() & 0xFF)) {
					dataPage = new bodyCompositionPage();
				}
				else if (metabolicPage.PAGE_NUMBER == (payload[0].toNumber() & 0xFF)) {
					dataPage = new metabolicPage();
				}
				else if (bodyMassPage.PAGE_NUMBER == (payload[0].toNumber() & 0xFF)) {
					dataPage = new bodyMassPage();
				}
				else if (commonManInfoPage.PAGE_NUMBER == (payload[0].toNumber() & 0xFF)) {
					dataPage = new commonManInfoPage();
				}
				else if (commonProductPage.PAGE_NUMBER == (payload[0].toNumber() & 0xFF)) {
					dataPage = new commonProductPage();
				}
				else if (tanitaDataPage.PAGE_NUMBER == (payload[0].toNumber() & 0xFF)) {
					dataPage = new tanitaDataPage();
				}
				else {
					Sys.println("something else");
				}

				if (dataPage) {
					dataPage.parse(payload, userData);
					Ui.requestUpdate();
				}

				dataPage = null;
			}
		}
		else if (Ant.MSG_ID_CHANNEL_RESPONSE_EVENT == msg.messageId) {
			if (Ant.MSG_ID_RF_EVENT == (payload[0] & 0xFF)) {
				if (Ant.MSG_CODE_EVENT_CHANNEL_CLOSED == (payload[1] & 0xFF)) {
					Sys.println("channel closed");
				}
				else if (Ant.MSG_CODE_EVENT_RX_FAIL_GO_TO_SEARCH  == (payload[1] & 0xFF)) {
					Sys.println("rx fail : goto search");
					closeSensor();
				}
				else if (Ant.MSG_CODE_EVENT_RX_FAIL == (payload[1] & 0xFF)) {
					Sys.println("rx fail");
				}
				else if (Ant.MSG_CODE_EVENT_TRANSFER_TX_FAILED == (payload[1] & 0xFF)) {
					Sys.println("tx fail");
				}
				else if (Ant.MSG_CODE_EVENT_TX == (payload[1] & 0xFF)) {
					Sys.println("tx Msg");
				}
				else if (Ant.MSG_CODE_EVENT_TRANSFER_TX_COMPLETED == (payload[1] & 0xFF)) {
					Sys.println("tx complete");
				}
			}
		}
		else if (Ant.MSG_ID_OPEN_CHANNEL == msg.messageId) {
			Sys.println("open channel");
		}
		else {
			Sys.println("payload | " + payload[0] + ":" + payload[1] + ":" + payload[2] + ":" + payload[3] + ":" + payload[4] + ":" + payload[5] + ":" + payload[6] + ":" + payload[7]);
		}
	}

	function sendUserProfile() {
		if (searching) {

			var payload = new [8];

			payload[0] = 0x3A; // user profile page 58 (0x3A)
			payload[1] = (userData.profileID & 0xFF); // Byte 1 & 2: user profile ID
			payload[2] = ((userData.profileID >> 8) & 0xFF);
			payload[3] = 0x24; // Bits: no scale profile | send user profile | no ANT-FS | send user data | NA | store profile
			payload[4] = 0xFF; // Reserved
			payload[5] = ((userData.age << 1) + userData.gender); // bits 0-6: age (34) | bit 7: gender (m)
			payload[6] = userData.height; // height in cm
			payload[7] = 0xA1; // [5,1] bits 0-2: activity level (0-7) | 0000 | bit 7: athlete class (0 or 1)			//userdata - temp hard code - need to change

			// Form and send the message
			var message = new Ant.Message();
			message.setPayload(payload);
			GenericChannel.sendBroadcast(message);
			var payloadString = "sent[8]";
			for (var i = 0; i < payload.size(); i++) {
				payloadString = payloadString + ":" + payload[i];
			}
		Sys.println(payloadString);

				searching = false;
		}

		return true;
	}
}