using Toybox.Lang as Lang;
using Toybox.System as Sys;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;

class weightScaleView extends Ui.View {

	hidden var mSensor;

	function initialize(sensor) {
		View.initialize();
		mSensor = sensor;
	}

	// Load your resources here
	function onLayout(dc) {
		setLayout(Rez.Layouts.MainLayout(dc));
		Sys.println(mSensor.userData.gender + " " + mSensor.userData.height + " " + mSensor.userData.activityClass + " " + mSensor.userData.birthYear);
	}

	// Called when this View is brought to the foreground. Restore
	// the state of this View and prepare it to be shown. This includes
	// loading resources into memory.
	function onShow() {
	}

	// Update the view
	function onUpdate(dc) {
 		// Call the parent onUpdate function to redraw the layout
	View.onUpdate(dc);
    }

	// Called when this View is removed from the screen. Save the
	// state of this View here. This includes freeing resources from
	// memory.
	function onHide() {
	}
}