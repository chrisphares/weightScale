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
	}

	function onShow() {
	}

	// Update the view
	function onUpdate(dc) {

		View.onUpdate(dc);

		if (mSensor.searching) {
			dc.drawText(dc.getWidth()/2, dc.getHeight()/2, Gfx.FONT_MEDIUM, "Searching...", Gfx.TEXT_JUSTIFY_CENTER);
		}
		else {
			dc.drawText(dc.getWidth()/2, dc.getHeight()/2, Gfx.FONT_MEDIUM, "not Searching", Gfx.TEXT_JUSTIFY_CENTER);
		}
    }

	function onHide() {
	}
}