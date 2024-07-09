package vortex.util;

import vortex.data.song.SongData.SongNoteData;
import vortex.data.song.SongData.SongEventData;
import flixel.util.FlxSort;

class SortUtil {
  public static function byStrumtime(order:Int, a:Note, b: Note): Int {
    return noteDataByTime(order, a.noteData, b.noteData);
  }
  public static function noteDataByTime(order: Int, a:SongNoteData, b: SongNoteData): Int {
    return FlxSort.byValues(order, a.rowTime, b.rowTime);
  }
  public static function eventDataByTime(order: Int, a:SongEventData, b:SongEventData): Int {
    return FlxSort.byValues(order, a.rowTime, b.rowTime);
  }
}
