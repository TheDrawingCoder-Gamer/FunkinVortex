package vortex.data.song;

import flixel.util.FlxSort;
import vortex.data.song.SongData.SongTimeChange;

class SongDataUtils {
  public static function sortTimeChanges(timeChanges: Array<SongTimeChange>, desc: Bool = false): Array<SongTimeChange> {
    timeChanges.sort(function(a:SongTimeChange,b:SongTimeChange): Int {
      return FlxSort.byValues(desc ? FlxSort.DESCENDING : FlxSort.ASCENDING, a.timeStamp, b.timeStamp);
    });
    return timeChanges;
  }
}
