import Toybox.Lang;
import Toybox.Activity;

module Everest {
module Util {

function Time(info as Activity.Info?) as Lang.Number {
    if (info instanceof Activity.Info and info has :elapsedTime) {
        var time = info.elapsedTime;
        if (time instanceof Lang.Number) {
            return time / 1000;
        }
    }
    return -1;
} // fn: Everest.Util.Time

module Format {

function Time(value as Lang.Number) as Lang.String {
    var m = (value/60).toNumber() % 60;
    var s = value % 60;
    if (value >= 3600) {
        var h = (value/3600).toNumber();
        return h.format("%d") + ":" + m.format("%02d") + ":" + s.format("%02d");
    } else if (m < 10) {
        return m.format("%d") + ":" + s.format("%02d");
    } else {
        return m.format("%02d") + ":" + s.format("%02d");
    }
} // fn: Everest.Util.Format.Time

} // module: Everest.Util.Format
} // module: Everest.Util
} // module: Everest