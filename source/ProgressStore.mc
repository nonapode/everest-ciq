import Toybox.Application;
import Toybox.Lang;

module Everest {
// Small, transition-driven persistence layer. It stores completed lap durations,
// not live GPS coordinates or an in-progress ascent.
module ProgressStore {
    const KEY_SNAPSHOT = "everestProgressV2";
    const KEY_ELAPSED = "everestLastElapsedV2";

    function load() as Dictionary? {
        try {
            var value = Application.Storage.getValue(KEY_SNAPSHOT);
            if (value instanceof Dictionary) {
                return value as Dictionary;
            }
        } catch (exception instanceof Lang.Object) {
            // Storage may be empty or unavailable on the first run.
        }
        return null;
    }

    function lastElapsed() as Lang.Number {
        try {
            var value = Application.Storage.getValue(KEY_ELAPSED);
            if (value instanceof Lang.Number) { return value; }
        } catch (exception instanceof Lang.Object) {
        }
        return -1;
    }

    function save(snapshot as Dictionary, elapsed as Lang.Number) as Void {
        try {
            Application.Storage.setValue(KEY_SNAPSHOT, snapshot);
            Application.Storage.setValue(KEY_ELAPSED, elapsed);
        } catch (exception instanceof Lang.Object) {
            // Never interrupt live tracking because persistence failed.
        }
    }

    function clear() as Void {
        try {
            Application.Storage.deleteValue(KEY_SNAPSHOT);
            Application.Storage.deleteValue(KEY_ELAPSED);
        } catch (exception instanceof Lang.Object) {
        }
    }
}
}
