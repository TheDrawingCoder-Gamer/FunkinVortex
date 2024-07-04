package vortex.data.song.vslice;

import flixel.util.FlxSort;
import vortex.data.song.vslice.SongData.SongTimeChange;

class SongDataUtils {
  public static function sortTimeChanges(timeChanges: Array<SongTimeChange>, desc: Bool = false): Array<SongTimeChange> {
    timeChanges.sort(function(a:SongTimeChange,b:SongTimeChange): Int {
      return FlxSort.byValues(desc ? FlxSort.DESCENDING : FlxSort.ASCENDING, a.timeStamp, b.timeStamp);
    });
    return timeChanges;
  }
  public static function quantizeNote(beatLength: Float, strum: Float): Int {
    final measureTime = beatLength * 4;

    final smallestDeviation = measureTime / Constants.QUANT_ARRAY[Constants.QUANT_ARRAY.length - 1];

    for (quant in 0...Constants.QUANT_ARRAY.length) {
      final quantTime = (measureTime / Constants.QUANT_ARRAY[quant]);
      if ((strum + smallestDeviation) % quantTime < smallestDeviation * 2) {
        return quant;
      }
    }
    return 0;
  }
  public static function quantizeNoteTime(timeChange: SongTimeChange, strum: Float): Int {
    final beatLength = timeChange.beatLengthMs();
    return quantizeNote(beatLength, strum);
  }
}
