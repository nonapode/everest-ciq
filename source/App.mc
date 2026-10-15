import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

module Everest {
class App extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    //! Return the initial view of your application here
    function getInitialView() as [Views] or [Views, InputDelegates] {
        // Clamp invalid user settings to safe defaults rather than failing at startup.
        var ascents = Property.PositiveNumber("ascents", 105, 1, 10000);
        var ascent = Property.PositiveDouble("ascent", 86.0d, 1.0d, 2000.0d);
        var radius = Property.PositiveDouble("radius", 15.0d, 3.0d, 250.0d);
        var top = Point.from(Property.Location("segmentTop"));
        var bot = Point.from(Property.Location("segmentBot"));

        var segment = new Segment(top, bot, ascent, radius);
        var view = new View(segment, ascents);
        var input = new Input(view);

        return [ view, input ];
    }
} // class: Everest.App
} // module: Everest

//function getApp() as EverestApp {
//    return Application.getApp() as EverestApp;
//}
