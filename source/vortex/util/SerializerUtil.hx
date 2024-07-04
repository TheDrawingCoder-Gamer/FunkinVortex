package vortex.util;

import haxe.Json;
import thx.semver.Version;

class SerializerUtil {
  static function replacer(key: String, value: Dynamic): Dynamic {
    if (key == "version") {
      if (Std.isOfType(value, String)) return value;
      
      return serializeVersion(cast value);
    }

    return value;
  }
  static inline function serializeVersion(version: Version): String {
    return version.toString();
  }

  public static function toJSON(input: Dynamic, pretty:Bool = true): String {
    return Json.stringify(input, replacer, pretty ? "\t" : null);
  }

    /**
   * Convert a JSON string to a Haxe object.
   */
  public static function fromJSON(input:String):Dynamic
  {
    try
    {
      return Json.parse(input);
    }
    catch (e)
    {
      trace('An error occurred while parsing JSON from string data');
      trace(e);
      return null;
    }
  }
}
