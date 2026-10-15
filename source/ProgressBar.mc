import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

module Everest {
class ProgressBar extends Drawable {
    private var progress as Lang.Float = 0.0;

    (:typecheck(false))
    function initialize(progress as Lang.Numeric, settings as Dictionary) {
        Drawable.initialize(settings);
        self.setProgress(progress);
    }

    function setProgress(progress as Lang.Numeric) as Void {
        progress = progress.toFloat();
        if (progress > 1.0) {
            progress = 1.0;
        } else if (progress < 0.0) {
            progress = 0.0;
        }
        self.progress = progress;
    }

    function draw(dc as Graphics.Dc) as Void {
        if (self.isVisible) {
            dc.setColor(Theme.Current.highlight, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(self.locX, self.locY, self.progress * self.width, self.height);
        }
    }

} // class: Everest.ProgressBar
} // module: Everest