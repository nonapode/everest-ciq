module Everest {
class Theme {
    typedef Color as $.Toybox.Graphics.ColorType;
    public var foreground as Color;
    public var background as Color;
    public var highlight as Color;

    (:typecheck(false))
    static function style(symbol as $.Toybox.Lang.Symbol, fallback as Color) as Color {
        var object = $.Rez;
        var path = [ :Styles, symbol, :color ];
        for (var i=0; i<path.size(); ++i) {
            symbol = path[i];
            if (object has symbol) {
                object = object[symbol];
            } else {
                return fallback;
            }
        }
        return object as Color;
    }

    static const LIGHT = new Theme(style(:system_color_light__text, $.Toybox.Graphics.COLOR_BLACK),
                                   style(:system_color_light__background, $.Toybox.Graphics.COLOR_WHITE),
                                   $.Toybox.Graphics.COLOR_DK_GREEN);
    static const DARK = new Theme(style(:system_color_dark__text, $.Toybox.Graphics.COLOR_WHITE),
                                  style(:system_color_dark__background, $.Toybox.Graphics.COLOR_BLACK),
                                  $.Toybox.Graphics.COLOR_DK_GREEN);

    function initialize(foreground as Color, background as Color, highlight as Color) {
        self.foreground = foreground;
        self.background = background;
        self.highlight = highlight;
    }

    static function select(bg as Color) as Theme {
        var select = Current;
        if (bg == DARK.background || bg == $.Toybox.Graphics.COLOR_BLACK) {
            select = DARK;
        } else {
            select = LIGHT;
        }
        if (select != Current) {
            $.Toybox.System.println("switch theme");
            Current = select;
        }
        return select;
    }

    static var Current as Theme = LIGHT;
} // class: Everest.Theme
} // module: Everest