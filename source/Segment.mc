import Toybox.Lang;
import Toybox.Math;

module Everest {
class Segment {
    typedef Mode as Lang.Number;
    enum { // mode
        INIT,
        BOT,
        ASCENT,
        TOP,
        DESCENT
    }

    static const MODECHAR = {
        INIT => '?',
        BOT => '_',
        TOP => '^',
        ASCENT => '/',
        DESCENT => '\\',
    };

    private var top as Point;
    private var bot as Point;
    private var radius as Lang.Numeric;

    public var idle as Lang.Numeric = 0;

    public var ascent as Lang.Numeric;
    private var ascents as Array<Lang.Number> = new [0] as Array<Lang.Number>;
    private var ascentCount as Lang.Number = 0;
    private var descents as Array<Lang.Number> = new [0] as Array<Lang.Number>;

    private var start as $.Toybox.Activity.Info? = null;
    private var mode as Mode = INIT;

    private var nearest as Point? = null;
    // Require two consecutive fixes for a transition. This adds at most about
    // one update interval of latency and filters single-fix GPS spikes.
    private var pendingMode as Mode? = null;
    private var pendingCount as Lang.Number = 0;
    private var worstTop as Lang.Numeric = 0;
    private var worstBot as Lang.Numeric = 0;

    static function SteinlingerBerg(radius as Lang.Numeric) as Segment {
        var top = new $.Toybox.Position.Location({
            :latitude => 49.57480171232313,
            :longitude => 11.701206327230679,
            :format => :degrees});
        var bot = new $.Toybox.Position.Location({
            :latitude => 49.56923988735744,
            :longitude => 11.712261539721053,
            :format => :degrees});
        return new Segment(Point.from(top), Point.from(bot), 86, radius);
    }

    function initialize(top as Point, bot as Point, ascent as Lang.Numeric, radius as Lang.Numeric) {
        self.top = top;
        self.bot = bot;
        self.radius = radius;
        self.ascent = ascent;
    }

    private function inRange(a as Point, b as Point) as Lang.Boolean {
        var distance = b.distance(a);
        return distance <= radius;
    }

    private function StateMachine(mode as Mode, point as Point) as Mode? {
        if (mode == INIT) {
            if (inRange(top, point)) {
                return TOP;
            } else if (inRange(bot, point)) {
                return BOT;
            }
        } else if (mode == BOT) {
            if (!inRange(bot, point)) {
                return ASCENT;
            }
        } else if (mode == ASCENT) {
            if (inRange(top, point)) {
                return TOP;
            } else if (inRange(bot, point)) {
                return BOT;
            }
        } else if (mode == TOP) {
            if (!inRange(top, point)) {
                return DESCENT;
            }
        } else if (mode == DESCENT) {
            if (inRange(bot, point)) {
                return BOT;
            } else if (inRange(top, point)) {
                return TOP;
            }
        }
        return null;
    }

    function update(info as $.Toybox.Activity.Info) as Mode? {
        if (!(info has :currentLocation) || !(info.currentLocation instanceof $.Toybox.Position.Location)) {
            return null;
        }
        var point = Point.from(info.currentLocation as $.Toybox.Position.Location);
        var time = Util.Time(info);

        // Seed the nearest-point tracker before any state transition can use it.
        if (self.nearest == null) {
            self.nearest = point;
        }

        var mode = self.mode;
        if (info has :currentSpeed && (mode == BOT || mode == TOP)) {
            var speed = info.currentSpeed;
            if (speed instanceof Lang.Float) {
                if (speed == 0) {
                    self.idle = self.idle + 1;
                }
            }
        }
        var proposed = StateMachine(mode, point);
        var next = null;
        if (proposed == null) {
            pendingMode = null;
            pendingCount = 0;
        } else if (pendingMode != null && pendingMode == proposed) {
            pendingCount += 1;
            if (pendingCount >= 2) {
                next = proposed;
                pendingMode = null;
                pendingCount = 0;
            }
        } else {
            pendingMode = proposed;
            pendingCount = 1;
        }

        if (next == null) {
            // no state change
            if (mode == TOP) {
                var nearest = self.nearest as Point;
                if (top.distance(nearest) > top.distance(point)) {
                    self.nearest = point;
                }
            } else if (mode == BOT) {
                var nearest = self.nearest as Point;
                if (bot.distance(nearest) > bot.distance(point)) {
                    self.nearest = point;
                }
            }
            return null;
        }
        var nearest = self.nearest as Point;
        if (mode == TOP) {
            var distance = top.distance(nearest);
            if (distance > worstTop) {
                worstTop = distance;
            }

        } else if (mode == BOT) {
            var distance = bot.distance(nearest);
            if (distance > worstBot) {
                worstBot = distance;
            }

        }
        self.nearest = point;

        self.mode = next;
        if (mode == DESCENT && next == BOT) {
            var startTime = Util.Time(start);
            var delta = time - startTime;
            if (startTime >= 0 && delta > 0) {
                descents.add(delta);
            }
        } else if (mode == ASCENT && next == TOP) {
            // Count the completed summit independently of timing availability.
            ascentCount += 1;
            var startTime = Util.Time(start);
            var delta = time - startTime;
            if (startTime >= 0 && delta > 0) {
                ascents.add(delta);
            }
        }
        start = info;
        return next;
    }

    private function last(array as Array<Lang.Number>) as Lang.Number {
        var size = array.size();
        if (size == 0) {
            return 0;
        }
        return array[size-1] as Lang.Number;
    }

    private function mean(array as Array<Lang.Number>) as Lang.Number {
        if (array.size() == 0) {
            return 0;
        }
        var mean = Math.mean(array as Array<Lang.Double or Lang.Float or Lang.Long or Lang.Number>);
        return Math.round(mean).toNumber();
    }

    function getAscentCount() as Lang.Number {
        return ascentCount;
    }

    function getTimedAscentCount() as Lang.Number {
        return ascents.size();
    }

    function lastAscent() as Lang.Number {
        return last(ascents);
    }

    function meanAscent() as Lang.Number {
        return mean(ascents);
    }

    function getDescentCount() as Lang.Number {
        return descents.size();
    }

    function lastDescent() as Lang.Number {
        return last(descents);
    }

    function meanDescent() as Lang.Number {
        return mean(descents);
    }

    function minAscent() as Lang.Number { return extreme(ascents, true); }
    function maxAscent() as Lang.Number { return extreme(ascents, false); }
    function minDescent() as Lang.Number { return extreme(descents, true); }
    function maxDescent() as Lang.Number { return extreme(descents, false); }

    private function extreme(array as Array<Lang.Number>, minimum as Lang.Boolean) as Lang.Number {
        if (array.size() == 0) { return 0; }
        var result = array[0] as Lang.Number;
        for (var i = 1; i < array.size(); i += 1) {
            var value = array[i] as Lang.Number;
            if ((minimum && value < result) || (!minimum && value > result)) { result = value; }
        }
        return result;
    }

    // Snapshot only completed lap durations; the in-progress segment is intentionally
    // restarted in INIT after a field restart so a stale transition is never replayed.
    function snapshot() as Dictionary {
        return { :ascents => ascents, :ascentCount => ascentCount, :descents => descents };
    }

    function restore(snapshot as Dictionary) as Void {
        if (snapshot has :ascents && snapshot[:ascents] instanceof Array) {
            var savedAscents = snapshot[:ascents] as Array;
            for (var i = 0; i < savedAscents.size() && i < 10000; i += 1) {
                var value = savedAscents[i];
                if (value instanceof Lang.Number && value > 0) { ascents.add(value); }
            }
        }
        if (snapshot has :ascentCount && snapshot[:ascentCount] instanceof Lang.Number) {
            var count = snapshot[:ascentCount] as Lang.Number;
            if (count >= ascents.size() && count <= 10000) { ascentCount = count; }
            else { ascentCount = ascents.size(); }
        } else {
            ascentCount = ascents.size();
        }
        if (snapshot has :descents && snapshot[:descents] instanceof Array) {
            var savedDescents = snapshot[:descents] as Array;
            for (var j = 0; j < savedDescents.size() && j < 10000; j += 1) {
                var value = savedDescents[j];
                if (value instanceof Lang.Number && value > 0) { descents.add(value); }
            }
        }
        mode = INIT;
        nearest = null;
        pendingMode = null;
        pendingCount = 0;
        start = null;
    }

    function getStart(mode as Mode) as $.Toybox.Activity.Info? {
        return (mode == self.mode) ? start : null;
    }
} // class: Everest.Segment
} // module: Everest
