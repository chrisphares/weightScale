using Toybox.Ant as Ant;
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
		scaleData,
		userProfileData,
		bodyWeightData,
		bodyCompData,
		metabolicData,
		bodyMassData;

	class userInfo {
		var profileID,
			height,
			gender,
			age,
			activityClass,
			bodyWeight,
			hydration,
			bodyFat,
			activeRate,
			basalRate,
			muscleMasss,
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
		}
	}

	class scaleInfo {
		var manID,
			modelNumber;
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

	class bodyWeightPage {
		static const PAGE_NUMBER = 0x01;

		function parse(payload, userData) {
			userData.bodyWeight = parseBodyWeight(payload);
		}

		//add check for user profile ID

		//add scale capabilities check

		hidden function parseBodyWeight(payload) {
			return (payload[6] + payload[7]); //not quite yet
		}
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

		hidden function parseBodyFat(payload) {
			return (payload[6] + payload[7]); //not quite yet
		}
	}

	class metabolicPage {
		static const PAGE_NUMBER = 0x03;

		function parse(payload, userData) {
			userData.activeRate = parseActiveRate(payload);
			userData.basalRate = parseBasalRate(payload);
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
		}

		hidden function parseMuscleMass(payload) {
			return (payload[4] + payload[5]); //not quite yet
		}

		hidden function parseBoneMass(payload) {
			return (payload[6] + payload[7]); //not quite yet
		}
	}

	class commonManInfoPage {
		static const PAGE_NUMBER = 75;

		function parse(payload, userData) {
			scaleData.manID = parseManID(payload);
			scaleData.modelNumber = parseModelNumber(payload);
			Sys.println("recieve commona data page");
		}

		hidden function parseManID(payload) {
			return (payload[4] + ((payload[5] & 0xFF) << 8));
		}

		hidden function parseModelNumber(payload) {
			return (payload[6] + ((payload[7] & 0xFF) << 8));
		}
	}

	function initialize() {
		// Get the channel
		chanAssign = new Ant.ChannelAssignment(Ant.CHANNEL_TYPE_RX_NOT_TX, Ant.NETWORK_PLUS);
		GenericChannel.initialize(method(:onMessage), chanAssign);

		// Set the configuration
		deviceCfg = new Ant.DeviceConfig( {
			:deviceNumber => 0,					// Wildcard our search
			:deviceType => 119,					// 119 (0x77) weight scale type
			:transmissionType => 0,				// 0 for pairing
			:messagePeriod => 8192,				// 4Hz default
			:radioFrequency => 57,				// 57 (0x39) Ant+ Frequency
			:searchTimeoutLowPriority => 4,		// Timeout in 2.5s increment
			:searchThreshold => 0} );			// Pair to all transmitting sensors
		GenericChannel.setDeviceConfig(deviceCfg);

		searching = true;
		userData = new userInfo();
		scaleData = new scaleInfo();
    }

	function open() {
	// Open the channel
		GenericChannel.open();

		userData = new userInfo();
		userProfileData = new userProfilePage();

		searching = true;

		Sys.println("open channel");
	}

	function closeSensor() {
		GenericChannel.close();
		Sys.println("close channel");
	}

	function sendUserProfile() {
		if (!searching) {
			var payload = new [8];

			//userdata - temp hard code - need to change
			payload[0] = 0x3A; // user profile page 58 (3A)
			payload[1] = 0x0B; // Byte 1 & 2: user profile ID
			payload[2] = 0xAD; // 0BAD
			payload[3] = 0x24; // Bits: no scale profile | send user profile | no ANT-FS | send user data | NA | do no store profile
			payload[4] = 0xFF; // Reserved
			payload[5] = 0x45; // bits 0-6: age (34) | bit 7: gender (m)
			payload[6] = 0xB6; // height in cm
			payload[7] = 0xA1; // [5,1] bits 0-2: activity level (0-7) | 0000 | bit 7: athlete class (0 or 1)


			// Form and send the message
			var message = new Ant.Message();
			message.setPayload(payload);
			GenericChannel.sendAcknowledge(message);
			Sys.println("sent user profile data");
		}
	}

	function onMessage(msg) {
		// Parse the payload
		var payload = msg.getPayload();

		Sys.println("payload | " + payload[0] + ":" + payload[1] + ":" + payload[2] + ":" + payload[3] + ":" + payload[4] + ":" + payload[5] + ":" + payload[6] + ":" + payload[7]);

		if (Ant.MSG_ID_BROADCAST_DATA == msg.messageId) {

			var dataPage = null,
				data = null;

			if (bodyWeightPage.PAGE_NUMBER == (payload[0].toNumber() & 0xFF)) {
				dataPage = new bodyWeightPage();
				data = userData;
			}
			else if (bodyCompositionPage.PAGE_NUMBER == (payload[0].toNumber() & 0xFF)) {
				dataPage = new bodyCompositionPage();
				data = userData;
			}
			else if (metabolicPage.PAGE_NUMBER == (payload[0].toNumber() & 0xFF)) {
				dataPage = new metabolicPage();
				data = userData;
			}
			else if (bodyMassPage.PAGE_NUMBER == (payload[0].toNumber() & 0xFF)) {
				dataPage = new bodyMassPage();
				data = userData;
			}
			else if (commonManInfoPage.PAGE_NUMBER == (payload[0].toNumber() & 0xFF)) {
				dataPage = new bodyMassPage();
				data = scaleData;
			}
			else {
				Sys.println("other page:" + (payload[0].toNumber() & 0xFF));
				sendUserProfile();
			}

			if (dataPage) {
				searching = false;
				deviceCfg = GenericChannel.getDeviceConfig(); // evaluate purpose
				datapage.parse(payload, data);
				Ui.requestUpdate();
				Sys.println("datapage");
			}

			dataPage = null;
		}
		else if (Ant.MSG_ID_CHANNEL_RESPONSE_EVENT == msg.messageId) {
			if (Ant.MSG_ID_RF_EVENT == (payload[0] & 0xFF)) {
				if (Ant.MSG_CODE_EVENT_CHANNEL_CLOSED == (payload[1] & 0xFF)) {
					// Channel closed, re-open
					open();
				} else if (Ant.MSG_CODE_EVENT_RX_FAIL_GO_TO_SEARCH  == (payload[1] & 0xFF)) {
					searching = true;
					Ui.requestUpdate();
				}
			}
			else {
				//It is a channel response.
				Sys.println("channelresponse");
            }
		}
	}
}