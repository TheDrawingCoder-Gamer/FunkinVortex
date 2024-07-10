package vortex.util;

import vortex.data.song.SongData.SongNoteData;
import vortex.data.song.SongData.SongEventData;
import vortex.data.song.SongData.ChartKey;
import vortex.data.song.SongData.SongChart;
import vortex.data.song.Gamemode;
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

  static function priorityOfDiff(diff: String): Int {
    return switch (diff) {
      case 'beginner': 0;
      case 'easy': 1;
      case 'medium' | 'normal': 2;
      case 'hard': 3;
      case 'challenge': 4;
      case 'edit': 5;
      default: 6;
    };
  }
  static function priorityOfGamemode(gamemode: String): Int {
    return switch (Gamemode.gamemodeArr.map(it -> it.id).indexOf(gamemode)) {
      case -1: 1000000000;
      case res: res;
    };
  }
  public static function chartKey(order:Int, a:ChartKey, b:ChartKey): Int {
    final aDiff = priorityOfDiff(a.difficulty);
    final bDiff = priorityOfDiff(b.difficulty);
    switch (FlxSort.byValues(order, aDiff, bDiff)) {
      case 0:
      case res: return res;
    }
    final aGamemode = priorityOfGamemode(a.gamemode);
    final bGamemode = priorityOfGamemode(b.gamemode);
    return FlxSort.byValues(order, aGamemode, bGamemode);
  }
  public static function chartByKey(order:Int, a:SongChart, b:SongChart): Int {
    return chartKey(order, a.chartKey, b.chartKey);
  }
}
