import Toybox.WatchUi;
import Toybox.Lang;

module Everest {
class Input extends WatchUi.InputDelegate {
    private var view as Lang.WeakReference;

    function initialize(view as View) {
        InputDelegate.initialize();
        self.view = view.weak();
    }

    function onTap(e as WatchUi.ClickEvent) as Lang.Boolean {
        var view = self.view.get();
        if (view instanceof View) {
            if (view.alert != null) {
                view.alert = null;
                return true;
            }
        }
        return InputDelegate.onTap(e);
    }
} // class: Everest.Input
} // module: Everest