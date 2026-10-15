import Toybox.WatchUi;
import Toybox.Lang;

module Everest {
class Timer extends WatchUi.Text {
    private var placeholder as Lang.String;

    function initialize(name as Lang.String) {
        self.placeholder = name;
        WatchUi.Text.initialize({:text => name});
    }

    function set(value as Lang.Number) as Void {
        if (value < 0) {
            setText(self.placeholder);
        } else {
            setText(Util.Format.Time(value));
        }
    }
} // class: Everst.Timer
} // module: Everest