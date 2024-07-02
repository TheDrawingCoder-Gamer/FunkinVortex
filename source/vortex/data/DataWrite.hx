package vortex.data;

import thx.semver.Version;
import thx.semver.VersionRule;

class DataWrite {
  public static function semverVersion(value: Version): String {
    return '"${value.toString()}"';
  }
  public static function semverVersionRule(value: VersionRule): String {
    return '"${value.toString()}"';
  }
  public static function dynamicValue(value: Dynamic): String {
    return vortex.util.SerializerUtil.toJSON(value);
  }
}
