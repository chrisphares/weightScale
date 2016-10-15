using Toybox.Application as App;
using Toybox.WatchUi as Ui;

class weightScaleApp extends App.AppBase {

	var mSensor;

	function initialize() {
		AppBase.initialize();
	}

	// onStart() is called on application start up
	function onStart(state) {
		//Create the sensor object and open it
		mSensor = new weightScaleSensor();
		mSensor.open();
	}

	// onStop() is called when your application is exiting
	function onStop(state) {
		// Release the sensor
		mSensor.release();
	}

	// Return the initial view of your application here
	function getInitialView() {
		return [new weightScaleView(mSensor)];
	}
}