using Toybox.System as Sys;
using Toybox.WatchUi as Ui;

class weightScaleDelegate extends Ui.BehaviorDelegate {

	var mSensor;

	function initialize(sensor) {
		BehaviorDelegate.initialize();
		mSensor = sensor;
	}

	function onKey(evt) {
		var key = evt.getKey();
		if (key == KEY_ENTER) {
			mSensor.open();
		}
		else if (key == KEY_ESC) {
			Sys.exit();
		}

		return true;
	}
}