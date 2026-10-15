import Toybox.Position;
import Toybox.Lang;
import Toybox.Math;

module Everest {
class Point {
    typedef Radian as Lang.Double;
    public var longitude as Radian;
    public var latitude as Radian;

    private function initialize(longitude as Radian, latitude as Radian) {
        self.longitude = longitude;
        self.latitude = latitude;
    }

    static public function parse(str as Lang.String, fmt as Position.CoordinateFormat) as Point {
        return from(Position.parse(str, fmt) as Position.Location);
    }

    static public function from(position as Position.Location) as Point {
        var radians = position.toRadians();
        return new Point(radians[0] as Radian, radians[1] as Radian);
    }

    public function distance(other as Point or Position.Location) as Lang.Double {
        if (other instanceof Position.Location) {
            other = from(other);
        }

        other = other as Point;

        var distance = Haversine(self.longitude, self.latitude, other.longitude, other.latitude);
        //System.println("Haversine(" + self.longitude + ", " + self.latitude + ", " + other.longitude + ", " + other.latitude + "): " + distance);
        return distance;
    }

    static function Haversine(longitude1 as Radian, latitude1 as Radian, longitude2 as Radian, latitude2 as Radian) as Lang.Double {
        var dlong = (longitude2 - longitude1)/2.0;
        var dlat = (latitude2 - latitude1)/2.0;
        var dlong_sin = Math.sin(dlong);
        var dlat_sin = Math.sin(dlat);

        var a = (dlat_sin*dlat_sin)+Math.cos(latitude1)*Math.cos(latitude2)*(dlong_sin*dlong_sin);
        // Floating-point rounding can push a just outside [0, 1].
        if (a < 0.0) {
            a = 0.0;
        } else if (a > 1.0) {
            a = 1.0;
        }
        var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));

        return 6367000 * c.abs().toDouble();
    }
} // class: Everest.Point
} // module: Everest