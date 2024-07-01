package vortex.data;

import hxjsonast.Json;
import hxjsonast.Json.JObjectField;
import hxjsonast.Tools;
import thx.semver.Version;
import thx.semver.VersionRule;

class DataParse {
  /**
   * `@:jcustomparse(vortex.data.DataParse.semverVersion)`
   * @param json Contains the `pos` and `value` of the property.
   * @param name The name of the property.
   * @return The value of the property as a `thx.semver.Version`.
   */
  public static function semverVersion(json:Json, name:String):Version
  {
    switch (json.value)
    {
      case JString(s):
        if (s == "") throw 'Expected version property $name to be non-empty.';
        return s;
      default:
        throw 'Expected version property $name to be a string, but it was ${json.value}.';
    }
  }

  /**
   * `@:jcustomparse(vortex.data.DataParse.semverVersionRule)`
   * @param json Contains the `pos` and `value` of the property.
   * @param name The name of the property.
   * @return The value of the property as a `thx.semver.VersionRule`.
   */
  public static function semverVersionRule(json:Json, name:String):VersionRule
  {
    switch (json.value)
    {
      case JString(s):
        if (s == "") throw 'Expected version rule property $name to be non-empty.';
        return s;
      default:
        throw 'Expected version rule property $name to be a string, but it was ${json.value}.';
    }
  }
}
