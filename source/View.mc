import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Position;
import Toybox.Activity;
import Toybox.Math;
import Toybox.Time;
import Toybox.FitContributor;
import Toybox.Attention;

module Everest {

class View extends WatchUi.DataField {
    private var segment as Segment;
    private var ascents as Lang.Number;
    private var ascentMin as Lang.Number = 0;
    private var ascentMax as Lang.Number = 0;
    private var descentMin as Lang.Number = 0;
    private var descentMax as Lang.Number = 0;
    private var persistenceChecked as Lang.Boolean = false;
    private var lastPersistElapsed as Lang.Number = -1;

    public var alert as WatchUi.DataFieldAlert?;
    private function _alert(alert as WatchUi.DataFieldAlert?) as Void {
        if (alert instanceof WatchUi.DataFieldAlert) {
            self.alert = alert;
        }
    }

    // drawables for Information
    private var dCounter as WatchUi.Text = new WatchUi.Text({:text => "#lap"});
    private var dMode as WatchUi.Text = new WatchUi.Text({
        :text => (Segment.MODECHAR[Segment.INIT] as Lang.Char).toString(),
        :font => Graphics.FONT_SYSTEM_XTINY,
        :locX => 2,
        :locY => Graphics.getFontHeight(Graphics.FONT_SYSTEM_XTINY)+2,
        :justification => Graphics.TEXT_JUSTIFY_LEFT,
    });
    private var dTimer as Timer = new Timer("timer");
    private var dMean as Timer = new Timer("avg");
    private var dMin as Timer = new Timer("min");
    private var dMax as Timer = new Timer("max");
    private var dProgress as ProgressBar = new ProgressBar(0.5, {});
    private var dAscent as WatchUi.Text = new WatchUi.Text({:text => "ascent"});
    private var dRemain as WatchUi.Text = new WatchUi.Text({:text => "remain"});
    private var dEstimated as Timer = new Timer("estimated");
    private var dElapsed as Timer = new Timer("elapsed");

    private var fAscentMean as FitContributor.Field?;
    private var fAscentMin as FitContributor.Field?;
    private var fAscentMax as FitContributor.Field?;

    private var fDescentMean as FitContributor.Field?;
    private var fDescentMin as FitContributor.Field?;
    private var fDescentMax as FitContributor.Field?;


    private function createField(name as Lang.String, fieldId as Lang.Number, type as FitContributor.DataType, options as {:units as Lang.String, :nativeNum as Lang.Number}) as FitContributor.Field? {
        if (!Property.Boolean("fit" + name)) {
            return null;
        }
        options[:mesgType] = FitContributor.MESG_TYPE_SESSION;
        try {
            return DataField.createField(name, fieldId, type, options);
        } catch (exception instanceof Lang.Object) {
            System.println(exception);
            return null;
        }
    }

    private function setField(field as FitContributor.Field?, value as Lang.Numeric) as Void {
        if (field instanceof FitContributor.Field) {
            field.setData(value);
        }
    }

    function initialize(segment as Segment, ascents as Lang.Number) {
        DataField.initialize();
        self.segment = segment;
        // Avoid invalid progress divisions when settings are edited or reset.
        self.ascents = ascents > 0 ? ascents : 1;

        fAscentMean = createField("AscentMean", 0, FitContributor.DATA_TYPE_DOUBLE, {:units => "seconds"});
        fAscentMin = createField("AscentMin", 1, FitContributor.DATA_TYPE_UINT32, {:units => "seconds"});
        fAscentMax = createField("AscentMax", 2, FitContributor.DATA_TYPE_UINT32, {:units => "seconds"});

        fDescentMean = createField("DescentMean", 3, FitContributor.DATA_TYPE_DOUBLE, {:units => "seconds"});
        fDescentMin = createField("DescentMin", 4, FitContributor.DATA_TYPE_UINT32, {:units => "seconds"});
        fDescentMax = createField("DescentMax", 5, FitContributor.DATA_TYPE_UINT32, {:units => "seconds"});
    }

    private function fontHeight(font as Graphics.FontType?) as Lang.Number {
        if (font == null) {
            return 0;
        }
        return Graphics.getFontHeight(font as Graphics.FontType);
    }

    typedef Layout as {:counter as Graphics.FontType, :elevation as Graphics.FontType, :time as Graphics.FontType, :mean as Graphics.FontType, :limit as Graphics.FontType};

    private function choose(dc as Dc, options as Array<Layout>) as Void {
        var border = 2;
        var height = dc.getHeight() - 2 * border;
        var width = dc.getWidth() - 2 * border;
        for (var i=0; i<options.size(); ++i) {
            var option = options[i] as Array;

            var counter = option[:counter] as Graphics.FontType?;
            var elevation = option[:elevation] as Graphics.FontType?;
            var time = option[:time] as Graphics.FontType?;
            var mean = option[:mean] as Graphics.FontType?;
            var limit = option[:limit] as Graphics.FontType?;

            var h = height - self.fontHeight(elevation);

            var l = self.fontHeight(counter);
            var r = self.fontHeight(time) + self.fontHeight(mean) + self.fontHeight(limit);

            var top = l > r ? l : r;

            if (top > h) {
                continue;
            }

            var padding = (h-top) / 3.0;
            var width2 = Math.floor((width-1)/2.0);
            // we can use this!
            /*
               <padding>  | <padding>
                          |    mean
                COUNTER   |   TIME
                          | min    max
               <padding/2>| </padding/2>
               -----------|-------------
                      <padding/2>
                done              remain
                      <padding>
            */

            if (counter != null && (mean != null || time != null || limit != null)) {
                self.layoutCounter(border, 0, padding, width2, top, counter);
                self.layoutTimer(border, width-width2, padding, width2, top, time, mean, limit);
            } else if (counter == null) {
                self.layoutCounter(border, 0, padding, width, top, counter as Graphics.FontType);
            } else if (mean != null || time != null || limit != null) {
                self.layoutTimer(border, 0, padding, width, top, time, mean, limit);
            }
            if (elevation != null) {
                self.layoutElevation(border, 0, 1.5 * padding + top, width, height - top - 1.5 * padding, elevation);
            }
            // Options are ordered largest to smallest: keep the first fitting layout.
            return;
        }
    }

    private function layoutCounter(border as Lang.Numeric, x as Lang.Numeric, y as Lang.Numeric, w as Lang.Numeric, h as Lang.Numeric, font as Graphics.FontType) as Void {
        dCounter.setLocation(x + w/2.0, y + h/2.0);
        dCounter.setFont(font);
        dCounter.setJustification(Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function layoutTimer(border as Lang.Numeric, x as Lang.Numeric, y as Lang.Numeric, w as Lang.Numeric, h as Lang.Numeric, font as Graphics.FontType?, mean as Graphics.FontType?, limit as Graphics.FontType?) as Void {
        if (limit != null) {
            var height = Graphics.getFontHeight(limit);
            dMin.setVisible(true);
            dMin.setLocation(x + border, y + h - height);
            dMin.setJustification(Graphics.TEXT_JUSTIFY_LEFT);
            dMin.setFont(limit);

            dMax.setVisible(true);
            dMax.setLocation(x + w - border, y + h - height);
            dMax.setJustification(Graphics.TEXT_JUSTIFY_RIGHT);
            dMax.setFont(limit);
        } else {
            dMin.setVisible(false);
            dMax.setVisible(false);
        }

        if (mean != null) {
            dMean.setVisible(true);
            dMean.setLocation(x + w/2, y);
            dMean.setJustification(Graphics.TEXT_JUSTIFY_CENTER);
            dMean.setFont(mean);
        } else {
            dMean.setVisible(false);
        }

        if (font != null) {
            dTimer.setVisible(true);
            dTimer.setLocation(x + w/2.0, y + h/2.0);
            dTimer.setFont(font);
            dTimer.setJustification(Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        } else {
            dTimer.setVisible(false);
        }
    }

    private function layoutElevation(border as Lang.Numeric, x as Lang.Numeric, y as Lang.Numeric, w as Lang.Numeric, h as Lang.Numeric, font as Graphics.FontType) as Void {
        if (h <= 0) {
            return;
        }
        dProgress.setLocation(x, y);
        dProgress.width = w;
        dProgress.height = h;

        dAscent.setFont(font);
        dAscent.setJustification(Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dAscent.setLocation(x + border, y + h/2.0);

        dRemain.setFont(font);
        dRemain.setJustification(Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
        dRemain.setLocation(x + w, y + h/2.0);

        dElapsed.setFont(font);
        dElapsed.setJustification(Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dElapsed.setLocation(x + w/2, y + h/4.0);

        dEstimated.setFont(font);
        dEstimated.setJustification(Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dEstimated.setLocation(x + w/2, y + 0.75 * h);
    }

    // Set your layout here. Anytime the size of obscurity of
    // the draw context is changed this will be called.
    function onLayout(dc as Dc) as Void {
        choose(dc, [
            {:counter => Graphics.FONT_SYSTEM_LARGE, :elevation => Graphics.FONT_SYSTEM_LARGE, :time => Graphics.FONT_SYSTEM_LARGE, :mean => Graphics.FONT_SYSTEM_LARGE, :limit => Graphics.FONT_SYSTEM_LARGE},
            {:counter => Graphics.FONT_SYSTEM_LARGE, :elevation => Graphics.FONT_SYSTEM_MEDIUM, :time => Graphics.FONT_SYSTEM_MEDIUM, :mean => Graphics.FONT_SYSTEM_XTINY, :limit => Graphics.FONT_SYSTEM_XTINY},
            {:counter => Graphics.FONT_SYSTEM_LARGE, :elevation => Graphics.FONT_SYSTEM_TINY, :time => Graphics.FONT_SYSTEM_MEDIUM, :mean => Graphics.FONT_SYSTEM_XTINY, :limit => Graphics.FONT_SYSTEM_XTINY},
        ] as Array<Layout>);
    }

    // The given info object contains all the current workout information.
    // Calculate a value and save it locally in this method.
    // Note that compute() and onUpdate() are asynchronous, and there is no
    // guarantee that compute() will be called before onUpdate().
    function compute(info as Activity.Info) as Void {
        var segment = self.segment;
        var time = Util.Time(info);
        if (time < 0) {
            return;
        }

        if (!persistenceChecked) {
            persistenceChecked = true;
            var previousElapsed = ProgressStore.lastElapsed();
            // Elapsed time moving backwards is our available signal for a new activity.
            // Reset only the challenge cache; this does not affect the FIT activity.
            if (previousElapsed >= 0 && time + 5 < previousElapsed) {
                ProgressStore.clear();
            } else {
                var saved = ProgressStore.load();
                if (saved instanceof Dictionary) {
                    segment.restore(saved as Dictionary);
                    lastPersistElapsed = previousElapsed;
                    // Rehydrate the visible summary and FIT fields from restored laps.
                    ascentMin = segment.minAscent();
                    ascentMax = segment.maxAscent();
                    descentMin = segment.minDescent();
                    descentMax = segment.maxDescent();
                    if (ascentMin > 0) { dMin.set(ascentMin); setField(fAscentMin, ascentMin); }
                    if (ascentMax > 0) { dMax.set(ascentMax); setField(fAscentMax, ascentMax); }
                    if (segment.meanAscent() > 0) { dMean.set(segment.meanAscent()); setField(fAscentMean, segment.meanAscent()); }
                    if (segment.meanDescent() > 0) { setField(fDescentMean, segment.meanDescent()); }
                    if (descentMin > 0) { setField(fDescentMin, descentMin); }
                    if (descentMax > 0) { setField(fDescentMax, descentMax); }
                }
            }
        }

        if (!(info has :currentLocation and info.currentLocation instanceof Position.Location)) {
            //System.println("no location!");
            return;
        }

        var modeswitch = segment.update(info);
        var ascents = segment.getAscentCount();
        if (modeswitch != null || lastPersistElapsed < 0 || time - lastPersistElapsed >= 60) {
            ProgressStore.save(segment.snapshot(), time);
            lastPersistElapsed = time;
        }
        var progress = -1;
        if (modeswitch == null) {
            var start = segment.getStart(Segment.ASCENT);
            if (start instanceof Activity.Info) {

                dTimer.set(Util.Time(info) - Util.Time(start));
                var ascent = info.totalAscent - start.totalAscent;
                var ascent_per_ascent = segment.ascent;
                if (ascent < 0) {
                    ascent = 0;
                } else if (ascent > ascent_per_ascent) {
                    ascent = ascent_per_ascent;
                }

                ascent += ascents * ascent_per_ascent;
                var total = ascent_per_ascent * self.ascents;
                progress = total > 0 ? ascent / total : 0.0;

                ascent = Math.round(ascent).toNumber();
                var remain = Math.round(total).toNumber() - ascent;

                dAscent.setText(ascent.format("%d"));
                dRemain.setText(remain.format("%d"));
                dProgress.setProgress(progress);
            }
        } else {
            dMode.setText((Segment.MODECHAR[modeswitch] as Lang.Char).toString());

            switch (modeswitch) {
            case Segment.TOP:
                var ascent_per_ascent = segment.ascent;
                var total = ascent_per_ascent * self.ascents;
                var ascent = ascents * ascent_per_ascent;
                progress = total > 0 ? ascent / total : 0.0;

                ascent = Math.round(ascent).toNumber();
                var remain = Math.round(total).toNumber() - ascent;

                dCounter.setText("#" + ascents);
                dAscent.setText(ascent.format("%d"));
                dRemain.setText(remain.format("%d"));
                dProgress.setProgress(progress);

                if (ascents > 0) {
                    var lastTime = segment.lastAscent();
                    if (lastTime > 0) {
                        if (segment.getTimedAscentCount() == 1) {
                            ascentMin = lastTime;
                            ascentMax = lastTime;
                            dMin.set(lastTime);
                            setField(fAscentMin, lastTime);
                            dMax.set(lastTime);
                            setField(fAscentMax, lastTime);
                        } else {
                            if (ascentMin == 0 || lastTime < ascentMin) {
                                ascentMin = lastTime;
                                dMin.set(lastTime);
                                setField(fAscentMin, lastTime);
                            }
                            if (lastTime > ascentMax) {
                                ascentMax = lastTime;
                                dMax.set(lastTime);
                                setField(fAscentMax, lastTime);
                            }
                        }
                        dMean.set(segment.meanAscent());
                        dTimer.set(lastTime);
                        setField(fAscentMean, segment.meanAscent());
                        WatchUi.showToast("#" + ascents.format("%d") + ": " + Util.Format.Time(lastTime), {});
                    } else {
                        // Count the summit even if the elapsed-time sample was invalid.
                        WatchUi.showToast("#" + ascents.format("%d") + " completed", {});
                    }
                }

                break;

            case Segment.BOT:
                var descents = segment.getDescentCount();
                if (descents > 0) {
                    var lastTime =  segment.lastDescent();
                    if (descents == 1) {
                        descentMin = lastTime;
                        descentMax = lastTime;
                        setField(fDescentMin, lastTime);
                        setField(fDescentMax, lastTime);
                    } else if (lastTime < descentMin) {
                        descentMin = lastTime;
                        setField(fDescentMin, lastTime);
                    } else if (lastTime > descentMax) {
                        descentMax = lastTime;
                        setField(fDescentMax, lastTime);
                    }
                    if (fDescentMean instanceof FitContributor.Field) {
                        setField(fDescentMean, segment.meanDescent());
                    }
                    WatchUi.showToast("#" + descents.format("%d") + ": " + Util.Format.Time(lastTime), {});
                }

                break;

            case Segment.DESCENT:
                break;
            case Segment.ASCENT:
                if ((ascents % 10) == 9) {
                    Attention.playTone({:toneProfile => RTTTL.onemoretime, :repeatCount => 1});
                } else if (ascents == 100) {
                    Attention.playTone({:toneProfile => RTTTL.countdown, :repeatCount => 1});
                }

                break;

            default:
                // TODO: implement specific cases
                System.println("modeswitch: " + modeswitch);
            }
        }
        if (progress == -1) {
            progress = ascents / self.ascents;
        }
        if (progress > 0.0 && progress <= 1.0) {
            dEstimated.set(Math.round(Util.Time(info) / progress).toNumber());
        }
        dElapsed.set(Util.Time(info));
    }

    static private function draw(dc as Graphics.Dc, drawable as WatchUi.Drawable) as Void {
        if (false) {
            // nothing
        } else if (drawable instanceof ProgressBar) {
            // nothing
        } else if (drawable instanceof WatchUi.Text) {
            drawable.setColor(Theme.Current.foreground);
        }
        drawable.draw(dc);
    }

    // Display the value you computed here. This will be called
    // once a second when the data field is visible.
    function onUpdate(dc as Dc) as Void {
        Theme.select(getBackgroundColor());

        // Call parent's onUpdate(dc) to redraw the layout
        dc.setColor(Theme.Current.background, Theme.Current.background);
        //dc.setColor(Theme.LIGHT.background, Theme.LIGHT.background);
        dc.clear();
        draw(dc, dMode);
        draw(dc, dProgress);
        draw(dc, dAscent);
        draw(dc, dRemain);
        draw(dc, dMin);
        draw(dc, dMax);
        draw(dc, dMean);
        draw(dc, dTimer);
        draw(dc, dCounter);
        draw(dc, dEstimated);
        draw(dc, dElapsed);

        var alert = self.alert;
        if (alert instanceof WatchUi.DataFieldAlert) {
            alert.onUpdate(dc);
        }
    }
} //class: Everest.View
} //module: Everest
