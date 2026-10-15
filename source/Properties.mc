import Toybox.Application;
import Toybox.Lang;
import Toybox.Position;

module Everest {
class Property {
    static public function Get(key as Application.PropertyKeyType) as Lang.Object {
        var value = Application.Properties.getValue(key);
        if (value instanceof Lang.Object) {
            return value;
        }
        throw new Lang.InvalidValueException(Lang.format("$1$: no such property", [key]));
    }

    static public function Convert(key as Application.PropertyKeyType, fn as Lang.Symbol) as Lang.Object {
        return Get(key).method(fn).invoke() as Lang.Object;
    }

    static public function Double(key as Application.PropertyKeyType) as Lang.Double {
        return Convert(key, :toDouble) as Lang.Double;
    }

    static public function Float(key as Application.PropertyKeyType) as Lang.Float {
        return Convert(key, :toFloat) as Lang.Float;
    }

    static public function Boolean(key as Application.PropertyKeyType) as Lang.Boolean {
        var value = Get(key);
        if (value instanceof Lang.Boolean) {
            return value;
        }
        throw new Lang.InvalidValueException(Lang.format("$1$: not a boolen object", [key]));
    }

    static public function Number(key as Application.PropertyKeyType) as Lang.Number {
        return Convert(key, :toNumber) as Lang.Number;
    }

    static public function GPSFormat() as Lang.Symbol {
        var format = 0;
        try {
            format = Number("gpsFormat");
        } catch (exception instanceof Lang.Object) {
            format = 0;
        }
        switch (format) {
        case 1:
            return :radians;
        case 2:
            return :semicircles;
        default:
            return :degrees;
        }
    }

    static public function PositiveDouble(key as Lang.String, fallback as Lang.Double, minValue as Lang.Double, maxValue as Lang.Double) as Lang.Double {
        var value = fallback;
        try {
            value = Double(key);
        } catch (exception instanceof Lang.Object) {
            value = fallback;
        }
        if (value < minValue || value > maxValue) {
            return fallback;
        }
        return value;
    }

    static public function PositiveNumber(key as Lang.String, fallback as Lang.Number, minValue as Lang.Number, maxValue as Lang.Number) as Lang.Number {
        var value = fallback;
        try {
            value = Number(key);
        } catch (exception instanceof Lang.Object) {
            value = fallback;
        }
        if (value < minValue || value > maxValue) {
            return fallback;
        }
        return value;
    }

    static public function Location(prefix as Lang.String) as Position.Location {
        var latitude = 0.0;
        var longitude = 0.0;
        try { latitude = Double(prefix + "Latitude"); } catch (exception instanceof Lang.Object) { latitude = 0.0; }
        try { longitude = Double(prefix + "Longitude"); } catch (exception instanceof Lang.Object) { longitude = 0.0; }
        // Reject impossible coordinates safely. Use the documented default segment
        // coordinates rather than allowing a bad setting to crash data-field startup.
        var format = GPSFormat();
        var valid = true;
        if (format == :degrees) {
            valid = latitude >= -90.0 && latitude <= 90.0 && longitude >= -180.0 && longitude <= 180.0;
        } else if (format == :radians) {
            valid = latitude >= -1.5707964 && latitude <= 1.5707964 && longitude >= -3.1415927 && longitude <= 3.1415927;
        }
        if (!valid) {
            if (prefix == "segmentTop") {
                latitude = 49.57480171232313;
                longitude = 11.701206327230679;
            } else {
                latitude = 49.56923988735744;
                longitude = 11.712261539721053;
            }
            format = :degrees;
        }
        return new Position.Location({ :latitude => latitude, :longitude => longitude, :format => format });
    }
}
}