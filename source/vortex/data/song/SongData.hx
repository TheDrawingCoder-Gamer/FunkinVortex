// stolen from V-Slice https://github.com/FunkinCrew/Funkin/blob/main/source/funkin/data/song/SongData.hx

package vortex.data.song;

#if !macro
import thx.semver.Version;
import thx.semver.VersionRule;
import vortex.util.ICloneable;
import vortex.data.song.vslice.SongData.SongChartData in VSliceChartData;
import vortex.data.song.vslice.SongData.SongMetadata in VSliceMetadata;
import vortex.data.song.vslice.SongData.SongTimeChange in VSliceTimeChange;
import vortex.data.song.vslice.SongData.SongEventData in VSliceEventData;
import vortex.data.song.vslice.SongData.SongNoteData in VSliceNoteData;
import vortex.data.song.vslice.SongData.SongPlayData in VSlicePlayData;
#end

class SongConstants {
  public static final SONG_DATA_VERSION: Version = "1.0.0";
  public static final SONG_DATA_VERSION_RULE: VersionRule = "1.0.x";
}
@:nullSafety
class SongData implements ICloneable<SongData>
{
  /**
   * A semantic versioning string for the song data format.
   *
   */
  // @:default(funkin.data.song.SongRegistry.SONG_METADATA_VERSION)
  @:jcustomparse(vortex.data.DataParse.semverVersion)
  @:jcustomwrite(vortex.data.DataWrite.semverVersion)
  public var version:Version;

  @:default("Unknown")
  public var songName:String;

  @:default("Unknown")
  public var artist:String;

  @:optional
  public var charter:Null<String> = null;

  /**
   * Instrumental and vocal offsets.
   * Defaults to an empty SongOffsets object.
   */
  @:optional
  public var offsets:Null<SongOffsets>;

  /**
   * Data relating to the song's gameplay.
   */
  public var playData:SongPlayData;

  @:default(vortex.util.Constants.GENERATED_BY)
  public var generatedBy:String;

  public var timeChanges:Array<SongTimeChange>;

  public var chart: SongCharts;

  @:optional
  public var variation: Null<String>;



  public function new(songName:String, artist:String, ?variation:String)
  {
    this.version = SongConstants.SONG_DATA_VERSION;
    this.songName = songName;
    this.artist = artist;
    this.offsets = new SongOffsets();
    this.timeChanges = [new SongTimeChange(0, 100)];
    this.playData = new SongPlayData();
    this.playData.songVariations = [];
    this.playData.difficulties = [];
    this.playData.characters = new SongCharacterData('bf', 'gf', 'dad');
    this.playData.stage = 'mainStage';
    this.playData.noteStyle = Constants.DEFAULT_NOTE_STYLE;
    this.generatedBy = Constants.GENERATED_BY;
    // Variation ID.
    this.variation = (variation == null) ? Constants.DEFAULT_VARIATION : variation;
    this.chart = new SongCharts([], []);
  }

  /**
   * Create a copy of this SongMetadata with the same information.
   * @param newVariation Set to a new variation ID to change the new metadata.
   * @return The cloned SongMetadata
   */
  public function clone():SongData
  {
    var result:SongData = new SongData(this.songName, this.artist, this.variation);
    result.version = this.version;
    result.offsets = this.offsets != null ? this.offsets.clone() : new SongOffsets(); // if no song offsets found (aka null), so just create new ones
    result.timeChanges = this.timeChanges.deepClone();
    result.playData = this.playData.clone();
    result.generatedBy = this.generatedBy;
    result.chart = this.chart.clone();
    result.charter = this.charter;

    return result;
  }

  /**
   * Serialize this SongMetadata into a JSON string.
   * @param pretty Whether the JSON should be big ol string (false),
   * or formatted with tabs (true)
   * @return The JSON string.
   */
  public function serialize(pretty:Bool = true):String
  {
    // Update generatedBy and version before writing.
    updateVersionToLatest();

    var ignoreNullOptionals = true;
    var writer = new json2object.JsonWriter<SongData>(ignoreNullOptionals);
    // I believe @:jignored should be ignored by the writer?
    // var output = this.clone();
    // output.variation = null; // Not sure how to make a field optional on the reader and ignored on the writer.
    return writer.write(this, pretty ? '  ' : null);
  }

  public function updateVersionToLatest():Void
  {
    this.version = SongConstants.SONG_DATA_VERSION;
    this.generatedBy = Constants.GENERATED_BY;
  }

  public static function deserialize(json: String): SongData {
    final reader = new json2object.JsonParser<SongData>();
    return reader.fromJson(json);
  }

  public static function fromVSlice(metadata: VSliceMetadata, chartData: VSliceChartData): SongData {
    final babyConductor = new LegacyConductor();
    babyConductor.mapTimeChanges(metadata.timeChanges);
    final newData = new SongData(metadata.songName, metadata.artist, metadata.variation);
    newData.charter = metadata.charter;
    newData.offsets = metadata.offsets?.clone() ?? new SongOffsets();
    newData.timeChanges = [for (m in metadata.timeChanges) SongTimeChange.fromVSlice(babyConductor, m)];
    newData.playData = SongPlayData.fromVSlice(metadata.playData);
    newData.chart = SongCharts.fromVSlice(babyConductor, metadata.playData, chartData);
    return newData;
  }

  public function toVSlice(): { metadata: VSliceMetadata, chartData: VSliceChartData} {
    final conductor = new Conductor();
    conductor.mapTimeChanges(timeChanges);
    final metadata = new VSliceMetadata(songName, artist, variation);
    metadata.charter = charter;
    metadata.offsets = offsets?.clone() ?? new SongOffsets();
    metadata.timeChanges = [for (m in timeChanges) m.toVSlice(conductor)];
    metadata.playData = playData.toVSlice();
    final daChart = chart?.toVSlice(conductor);
    if (daChart == null) throw "failed to convert chart";
    return {metadata: metadata, chartData: daChart };
  }
  /**
   * Produces a string representation suitable for debugging.
   */
  public function toString():String
  {
    return 'SongData(${this.songName} by ${this.artist}, variation ${this.variation})';
  }
}

class SongTimeChange implements ICloneable<SongTimeChange>
{
  public static final DEFAULT_SONGTIMECHANGE:SongTimeChange = new SongTimeChange(0, 100);

  public static final DEFAULT_SONGTIMECHANGES:Array<SongTimeChange> = [DEFAULT_SONGTIMECHANGE];

  static final DEFAULT_BEAT_TUPLETS:Array<Int> = [4, 4, 4, 4];
  static final DEFAULT_BEAT_TIME:Null<Float> = null; // Later, null gets detected and recalculated.

  /**
    * The "row" of a time change
    */
  @:alias("t")
  public var rowTime:Int;

  /**
   * Quarter notes per minute (float). Cannot be empty in the first element of the list,
   * but otherwise it's optional, and defaults to the value of the previous element.
   */
  @:alias("bpm")
  public var bpm:Float;

  /**
   * Time signature numerator (int). Optional, defaults to 4.
   */
  @:default(4)
  @:optional
  @:alias("n")
  public var timeSignatureNum:Int;

  /**
   * Time signature denominator (int). Optional, defaults to 4. Should only ever be a power of two.
   */
  @:default(4)
  @:optional
  @:alias("d")
  public var timeSignatureDen:Int;

  /**
   * Beat tuplets (Array<int> or int). This defines how many steps each beat is divided into.
   * It can either be an array of length `n` (see above) or a single integer number.
   * Optional, defaults to `[4]`.
   */
  @:optional
  @:alias("bt")
  public var beatTuplets:Array<Int>;

  // Time in ms. Calculated later
  @:jignored
  public var time: Null<Float> = null;

  public function new(rowTime:Int, bpm:Float, timeSignatureNum:Int = 4, timeSignatureDen:Int = 4, ?beatTuplets:Array<Int>)
  {
    this.rowTime = rowTime;
    this.bpm = bpm;

    this.timeSignatureNum = timeSignatureNum;
    this.timeSignatureDen = timeSignatureDen;

    this.beatTuplets = beatTuplets == null ? DEFAULT_BEAT_TUPLETS : beatTuplets;
  }

  public function clone():SongTimeChange
  {
    return new SongTimeChange(this.rowTime, this.bpm, this.timeSignatureNum, this.timeSignatureDen, this.beatTuplets);
  }

  /**
   * Produces a string representation suitable for debugging.
   */
  public function toString():String
  {
    return 'SongTimeChange(${this.rowTime} rows,${this.bpm}bpm)';
  }

  public static function fromVSlice(conductor: LegacyConductor, vslice: VSliceTimeChange): SongTimeChange {
    final rowTime = conductor.getTimeInRows(vslice.timeStamp);
    return new SongTimeChange(rowTime, vslice.bpm, vslice.timeSignatureNum, vslice.timeSignatureDen, vslice.beatTuplets);
  }
  public function toVSlice(conductor: Conductor): VSliceTimeChange {
    final msTime = time ?? conductor.getRowTimeInMs(rowTime);
    return new VSliceTimeChange(msTime, bpm, timeSignatureNum, timeSignatureDen, beatTuplets);
  }

  public function stepsPerMeasure(): Int {
    return Std.int(timeSignatureNum / timeSignatureDen * Constants.STEPS_PER_BEAT * Constants.STEPS_PER_BEAT);
  }
}

/**
 * Offsets to apply to the song's instrumental and vocals, relative to the chart.
 * These are intended to correct for issues with the chart, or with the song's audio (for example a 10ms delay before the song starts).
 * This is independent of the offsets applied in the user's settings, which are applied after these offsets and intended to correct for the user's hardware.
 */
class SongOffsets implements ICloneable<SongOffsets>
{
  /**
   * The offset, in milliseconds, to apply to the song's instrumental relative to the chart.
   * For example, setting this to `-10.0` will start the instrumental 10ms earlier than the chart.
   *
   * Setting this to `-5000.0` means the chart start 5 seconds into the song.
   * Setting this to `5000.0` means there will be 5 seconds of silence before the song starts.
   */
  @:optional
  @:default(0)
  public var instrumental:Float;

  /**
   * Apply different offsets to different alternate instrumentals.
   */
  @:optional
  @:default([])
  public var altInstrumentals:Map<String, Float>;

  /**
   * The offset, in milliseconds, to apply to the song's vocals, relative to the chart.
   * These are applied ON TOP OF the instrumental offset.
   */
  @:optional
  @:default([])
  public var vocals:Map<String, Float>;

  public function new(instrumental:Float = 0.0, ?altInstrumentals:Map<String, Float>, ?vocals:Map<String, Float>)
  {
    this.instrumental = instrumental;
    this.altInstrumentals = altInstrumentals == null ? new Map<String, Float>() : altInstrumentals;
    this.vocals = vocals == null ? new Map<String, Float>() : vocals;
  }

  public function getInstrumentalOffset(?instrumental:String):Float
  {
    if (instrumental == null || instrumental == '') return this.instrumental;

    if (!this.altInstrumentals.exists(instrumental)) return this.instrumental;

    return this.altInstrumentals.get(instrumental);
  }

  public function setInstrumentalOffset(value:Float, ?instrumental:String):Float
  {
    if (instrumental == null || instrumental == '')
    {
      this.instrumental = value;
    }
    else
    {
      this.altInstrumentals.set(instrumental, value);
    }
    return value;
  }

  public function getVocalOffset(charId:String):Float
  {
    if (!this.vocals.exists(charId)) return 0.0;

    return this.vocals.get(charId);
  }

  public function setVocalOffset(charId:String, value:Float):Float
  {
    this.vocals.set(charId, value);
    return value;
  }

  public function clone():SongOffsets
  {
    var result:SongOffsets = new SongOffsets(this.instrumental);
    result.altInstrumentals = this.altInstrumentals.clone();
    result.vocals = this.vocals.clone();

    return result;
  }

  /**
   * Produces a string representation suitable for debugging.
   */
  public function toString():String
  {
    return 'SongOffsets(${this.instrumental}ms, ${this.altInstrumentals}, ${this.vocals})';
  }
}

class SongPlayData implements ICloneable<SongPlayData>
{
  /**
   * The variations this song has. The associated metadata files should exist.
   */
  @:default([])
  @:optional
  public var songVariations:Array<String>;

  /**
   * The difficulties contained in this song's chart file.
   */
  public var difficulties:Array<String>;

  /**
   * The characters used by this song.
   */
  public var characters:SongCharacterData;

  /**
   * The stage used by this song.
   */
  public var stage:String;

  /**
   * The note style used by this song.
   */
  public var noteStyle:String;

  /**
   * The difficulty ratings for this song as displayed in Freeplay.
   * Key is a difficulty ID.
   */
  @:optional
  @:default(['normal' => 0])
  public var ratings:Map<String, Int>;

  @:optional
  @:default(['normal' => 0])
  public var stepmaniaRatings:Map<String, Float>;

  /**
   * The album ID for the album to display in Freeplay.
   * If `null`, display no album.
   */
  @:optional
  public var album:Null<String>;

  /**
   * The start time for the audio preview in Freeplay.
   * Defaults to 0 seconds in.
   * @since `2.2.2`
   */
  @:optional
  @:default(0)
  public var previewStart:Int;

  /**
   * The end time for the audio preview in Freeplay.
   * Defaults to 15 seconds in.
   * @since `2.2.2`
   */
  @:optional
  @:default(15000)
  public var previewEnd:Int;

  public function new()
  {
    ratings = new Map<String, Int>();
    stepmaniaRatings = new Map<String, Float>();
  }

  public function clone():SongPlayData
  {
    // TODO: This sucks! If you forget to update this you get weird behavior.
    var result:SongPlayData = new SongPlayData();
    result.songVariations = this.songVariations.clone();
    result.difficulties = this.difficulties.clone();
    result.characters = this.characters.clone();
    result.stage = this.stage;
    result.noteStyle = this.noteStyle;
    result.ratings = this.ratings.clone();
    result.album = this.album;
    result.previewStart = this.previewStart;
    result.previewEnd = this.previewEnd;

    return result;
  }

  /**
   * Produces a string representation suitable for debugging.
   */
  public function toString():String
  {
    return 'SongPlayData(${this.songVariations}, ${this.difficulties})';
  }

  public static function fromVSlice(raw: VSlicePlayData): SongPlayData {
    final result = new SongPlayData();
    result.songVariations = raw.songVariations.clone();
    result.difficulties = raw.difficulties.clone();
    result.characters = raw.characters.clone();
    result.stage = raw.stage;
    result.noteStyle = raw.noteStyle;
    result.album = raw.album;
    result.previewStart = raw.previewStart;
    result.previewEnd = raw.previewEnd;
    result.ratings = raw.ratings.clone();
    for (key => _ in raw.ratings) {
      result.stepmaniaRatings.set(key, 0);
    }

    return result;
  }
  public function toVSlice(): VSlicePlayData {
    final result = new VSlicePlayData();
    result.songVariations = songVariations.clone();
    result.difficulties = difficulties.clone();
    result.characters = characters.clone();
    result.stage = stage;
    result.noteStyle = noteStyle;
    result.album = album;
    result.previewStart = previewStart;
    result.previewEnd = previewEnd;
    result.ratings = ratings.clone();
    return result;
  }
}

/**
 * Information about the characters used in this variation of the song.
 * Create a new variation if you want to change the characters.
 */
class SongCharacterData implements ICloneable<SongCharacterData>
{
  @:optional
  @:default('')
  public var player:String = '';

  @:optional
  @:default('')
  public var girlfriend:String = '';

  @:optional
  @:default('')
  public var opponent:String = '';

  @:optional
  @:default('')
  public var instrumental:String = '';

  @:optional
  @:default([])
  public var altInstrumentals:Array<String> = [];

  public function new(player:String = '', girlfriend:String = '', opponent:String = '', instrumental:String = '')
  {
    this.player = player;
    this.girlfriend = girlfriend;
    this.opponent = opponent;
    this.instrumental = instrumental;
  }

  public function clone():SongCharacterData
  {
    var result:SongCharacterData = new SongCharacterData(this.player, this.girlfriend, this.opponent, this.instrumental);
    result.altInstrumentals = this.altInstrumentals.clone();

    return result;
  }

  /**
   * Produces a string representation suitable for debugging.
   */
  public function toString():String
  {
    return 'SongCharacterData(${this.player}, ${this.girlfriend}, ${this.opponent}, ${this.instrumental}, [${this.altInstrumentals.join(', ')}])';
  }
}

class SongCharts implements ICloneable<SongCharts>
{
  public var events:Array<SongEventData>;

  public var charts: Array<SongChart>;
  /**
   * Defaults to `Constants.DEFAULT_VARIATION`. Populated later.
   */
  @:jignored
  public var variation:String;

  public function new(events:Array<SongEventData>, charts: Array<SongChart>)
  {
    this.events = events;
    this.charts = charts;
  }
  /*
  public function getScrollSpeed(key:ChartKey):Float
  {
    var result:Float = this.charts.get(key)?.scrollSpeed ?? 0.0;


    return (result == 0.0) ? 1.0 : result;
  }

  public function setScrollSpeed(value:Float, key:ChartKey):Float
  {
    this.charts.get(key).scrollSpeed = value;
    return value;
  }
  */
  /*
  public function getNotes(key:ChartKey):Array<SongNoteData>
  {
    var result:Array<SongNoteData> = this.charts.get(key)?.notes;

    return (result == null) ? [] : result;
  }

  public function setNotes(value:Array<SongNoteData>, key:ChartKey):Array<SongNoteData>
  {
    this.charts.get(key).notes = value;
    return value;
  }
  */

  public function clone():SongCharts
  {
    final songChartClone = this.charts.clone();
    var eventDataClone:Array<SongEventData> = this.events.deepClone();

    var result:SongCharts = new SongCharts(eventDataClone, songChartClone);
    result.variation = this.variation;

    return result;
  }
  /**
   * Produces a string representation suitable for debugging.
   */
  public function toString():String
  {
    return 'SongCharts(${this.events.length} events)';
  }

  public static function fromVSlice(conductor: LegacyConductor, playdata: VSlicePlayData, chart: VSliceChartData): SongCharts {
    final chartData = [];
    for (key => notes in chart.notes) {
      final chartKey = new ChartKey(key, Constants.DANCE_COUPLE);
      chartData.push(new SongChart(chartKey, chart.scrollSpeed[key], [for (n in notes) SongNoteData.fromVSlice(conductor, n)], playdata.ratings[key], 0));
    }
    final eventData:Array<SongEventData> = [];
    for (event in chart.events) {
      eventData.push(SongEventData.fromVSlice(conductor, event));
    }
    final res = new SongCharts(eventData, chartData);
    res.variation = chart.variation;
    return res;
  }
  public function toVSlice(conductor: Conductor): VSliceChartData {
    final vsliceNoteData = new Map<String, Array<VSliceNoteData>>();
    final scrollSpeeds = new Map<String, Float>();
    for (chart in charts) {
      final key = chart.chartKey;
      if (key.gamemode != Constants.DANCE_COUPLE) continue;
      final diff = if (key.difficulty == "medium") "normal" else key.difficulty;
      vsliceNoteData.set(diff, [for (n in chart.notes) n.toVSlice(conductor)]);
      scrollSpeeds.set(diff, chart.scrollSpeed);
    }
    final vsliceEventData:Array<VSliceEventData> = [];
    for (event in events) {
      vsliceEventData.push(event.toVSlice(conductor));
    }
    final res = new VSliceChartData(scrollSpeeds, vsliceEventData, vsliceNoteData);
    res.variation = variation;
    return res;
  }
  public function defaultChart(): Null<ChartKey> {
    final keys = charts.map(it -> it.chartKey);
    if (keys.length == 0) return null;
    var bestMatch = keys[0];
    // TODO: make me work good
    for (key in keys) {
      if (!key.gamemode.startsWith("dance") && bestMatch.gamemode.startsWith("dance"))
        continue;
      if (key.gamemode == Constants.DANCE_SINGLE && bestMatch.gamemode != Constants.DANCE_SINGLE) {
        bestMatch = key;
      } else if (key.gamemode == bestMatch.gamemode && key.difficulty == "normal") {
        bestMatch = key;        
      }

    }
    return bestMatch;
  }

}


class SongChart implements ICloneable<SongChart> {
  public var chartKey: ChartKey;
  public var scrollSpeed: Float;
  public var notes: Array<SongNoteData>;
  public var rating: Int;
  public var stepmaniaRating: Float;
  public function new(key: ChartKey, scrollSpeed: Float, notes: Array<SongNoteData>, rating: Int, stepmaniaRating: Float) {
    this.chartKey = key;
    this.scrollSpeed = scrollSpeed;
    this.notes = notes;
    this.rating = rating;
    this.stepmaniaRating = stepmaniaRating;
  }
  public function clone(): SongChart {
    return new SongChart(chartKey, scrollSpeed, notes.deepClone(), rating, stepmaniaRating);
  }
  public function toString(): String {
    return 'SongChart(Scroll ${scrollSpeed}x, ${notes.length} notes)';
  }
}

class SongEventDataRaw implements ICloneable<SongEventDataRaw>
{
  /**
   * The timestamp of the event. The timestamp is in the format of the song's time format.
   */
  @:alias("t")
  public var rowTime:Int;

  /**
   * The kind of the event.
   * Examples include "FocusCamera" and "PlayAnimation"
   * Custom events can be added by scripts with the `ScriptedSongEvent` class.
   */
  @:alias("e")
  public var eventKind:String;

  /**
   * The data for the event.
   * This can allow the event to include information used for custom behavior.
   * Data type depends on the event kind. It can be anything that's JSON serializable.
   */
  @:alias("v")
  @:optional
  @:jcustomparse(vortex.data.DataParse.dynamicValue)
  @:jcustomwrite(vortex.data.DataWrite.dynamicValue)
  public var value:Dynamic = null;

  /**
   * Whether this event has been activated.
   * This is only used internally by the game. It should not be serialized.
   */
  @:jignored
  public var activated:Bool = false;

  public function new(time:Int, eventKind:String, value:Dynamic = null)
  {
    this.rowTime = time;
    this.eventKind = eventKind;
    this.value = value;
  }

  public function getStepTime(force:Bool = false):Float
  {

    return rowTime / Constants.ROWS_PER_STEP;
  }

  public function clone():SongEventDataRaw
  {
    return new SongEventDataRaw(this.rowTime, this.eventKind, this.value);
  }
}

/**
 * Wrap SongEventData in an abstract so we can overload operators.
 */
@:forward(rowTime, eventKind, value, activated, getStepTime, clone)
abstract SongEventData(SongEventDataRaw) from SongEventDataRaw to SongEventDataRaw
{
  public function new(time:Int, eventKind:String, value:Dynamic = null)
  {
    this = new SongEventDataRaw(time, eventKind, value);
  }

  public function valueAsStruct(?defaultKey:String = "key"):Dynamic
  {
    if (this.value == null) return {};
    if (Std.isOfType(this.value, Array))
    {
      var result:haxe.DynamicAccess<Dynamic> = {};
      result.set(defaultKey, this.value);
      return cast result;
    }
    else if (Reflect.isObject(this.value))
    {
      // We enter this case if the value is a struct.
      return cast this.value;
    }
    else
    {
      var result:haxe.DynamicAccess<Dynamic> = {};
      result.set(defaultKey, this.value);
      return cast result;
    }
  }

  /*
  public inline function getHandler():Null<SongEvent>
  {
    return SongEventRegistry.getEvent(this.eventKind);
  }

  public inline function getSchema():Null<SongEventSchema>
  {
    return SongEventRegistry.getEventSchema(this.eventKind);
  }
  */

  public inline function getDynamic(key:String):Null<Dynamic>
  {
    return this.value == null ? null : Reflect.field(this.value, key);
  }

  public inline function getBool(key:String):Null<Bool>
  {
    return this.value == null ? null : cast Reflect.field(this.value, key);
  }

  public inline function getInt(key:String):Null<Int>
  {
    if (this.value == null) return null;
    var result = Reflect.field(this.value, key);
    if (result == null) return null;
    if (Std.isOfType(result, Int)) return result;
    if (Std.isOfType(result, String)) return Std.parseInt(cast result);
    return cast result;
  }

  public inline function getFloat(key:String):Null<Float>
  {
    if (this.value == null) return null;
    var result = Reflect.field(this.value, key);
    if (result == null) return null;
    if (Std.isOfType(result, Float)) return result;
    if (Std.isOfType(result, String)) return Std.parseFloat(cast result);
    return cast result;
  }

  public inline function getString(key:String):String
  {
    return this.value == null ? null : cast Reflect.field(this.value, key);
  }

  public inline function getArray(key:String):Array<Dynamic>
  {
    return this.value == null ? null : cast Reflect.field(this.value, key);
  }

  public inline function getBoolArray(key:String):Array<Bool>
  {
    return this.value == null ? null : cast Reflect.field(this.value, key);
  }

  public function buildTooltip():String
  {
    return this.eventKind;
    //var eventHandler = getHandler();
    //var eventSchema = getSchema();

    /*
    if (eventSchema == null) return 'Unknown Event: ${this.eventKind}';

    var result = '${eventHandler.getTitle()}';

    var defaultKey = eventSchema.getFirstField()?.name;
    var valueStruct:haxe.DynamicAccess<Dynamic> = valueAsStruct(defaultKey);

    for (pair in valueStruct.keyValueIterator())
    {
      var key = pair.key;
      var value = pair.value;

      var title = eventSchema.getByName(key)?.title ?? 'UnknownField';

      // if (eventSchema.stringifyFieldValue(key, value) != null) trace(eventSchema.stringifyFieldValue(key, value));
      var valueStr = eventSchema.stringifyFieldValue(key, value) ?? 'UnknownValue';

      result += '\n- ${title}: ${valueStr}';
    }

    return result;
    */
  }

  public function clone():SongEventData
  {
    return new SongEventData(this.rowTime, this.eventKind, this.value);
  }

  @:op(A == B)
  public function op_equals(other:SongEventData):Bool
  {
    return this.rowTime == other.rowTime && this.eventKind == other.eventKind && this.value == other.value;
  }

  @:op(A != B)
  public function op_notEquals(other:SongEventData):Bool
  {
    return this.rowTime != other.rowTime || this.eventKind != other.eventKind || this.value != other.value;
  }

  @:op(A > B)
  public function op_greaterThan(other:SongEventData):Bool
  {
    return this.rowTime > other.rowTime;
  }

  @:op(A < B)
  public function op_lessThan(other:SongEventData):Bool
  {
    return this.rowTime < other.rowTime;
  }

  @:op(A >= B)
  public function op_greaterThanOrEquals(other:SongEventData):Bool
  {
    return this.rowTime >= other.rowTime;
  }

  @:op(A <= B)
  public function op_lessThanOrEquals(other:SongEventData):Bool
  {
    return this.rowTime <= other.rowTime;
  }

  /**
   * Produces a string representation suitable for debugging.
   */
  public function toString():String
  {
    return 'SongEventData(${this.rowTime} rows, ${this.eventKind}: ${this.value})';
  }

  public static function fromVSlice(conductor: LegacyConductor, raw: VSliceEventData): SongEventData {
    final rowTime = conductor.getTimeInRows(raw.time);
    return new SongEventData(rowTime, raw.eventKind, raw.value);
  }
  public function toVSlice(conductor: Conductor): VSliceEventData {
    final msTime = conductor.getRowTimeInMs(this.rowTime);
    return new VSliceEventData(msTime, this.eventKind, this.value);
  }
}

class SongNoteDataRaw implements ICloneable<SongNoteDataRaw>
{
  /**
   * The timestamp of the note. The timestamp is in the 192nds of a measure (rows)
   */
  @:alias("t")
  public var rowTime:Int;


  /**
   * Data for the note. Represents the index on the strumline.
   * 0 = left, 1 = down, 2 = up, 3 = right
   * `floor(direction / strumlineSize)` specifies which strumline the note is on.
   * 0 = player, 1 = opponent, etc.
   */
  @:alias("d")
  public var data:Int;

  /**
   * Length of the note, if applicable.
   * Defaults to 0 for single notes.
   */
  @:alias("l")
  @:default(0)
  @:optional
  public var length:Int;


  /**
   * The kind of the note.
   * This can allow the note to include information used for custom behavior.
   * Defaults to `null` for no kind.
   */
  @:alias("k")
  @:optional
  @:isVar
  public var kind(get, set):Null<String> = null;

  function get_kind():Null<String>
  {
    if (this.kind == null || this.kind == '') return null;

    return this.kind;
  }

  function set_kind(value:Null<String>):Null<String>
  {
    if (value == '') value = null;
    return this.kind = value;
  }

  public function new(time:Int, data:Int, length:Int = 0, kind:String = '')
  {
    this.rowTime = time;
    this.data = data;
    this.length = length;
    this.kind = kind;
  }

  /**
   * The direction of the note, if applicable.
   * Strips the strumline index from the data.
   *
   * 0 = left, 1 = down, 2 = up, 3 = right
   */
  public inline function getDirection(strumlineSize:Int = 4):Int
  {
    return this.data % strumlineSize;
  }

  public function getDirectionName(strumlineSize:Int = 4):String
  {
    return SongNoteData.buildDirectionName(this.data, strumlineSize);
  }

  /**
   * The strumline index of the note, if applicable.
   * Strips the direction from the data.
   *
   * 0 = player, 1 = opponent, etc.
   */
  public function getStrumlineIndex(strumlineSize:Int = 4):Int
  {
    return Math.floor(this.data / strumlineSize);
  }

  /**
   * Returns true if the note is one that Boyfriend should try to hit (i.e. it's on his side).
   * TODO: The name of this function is a little misleading; what about mines?
   * @param strumlineSize Defaults to 4.
   * @return True if it's Boyfriend's note.
   */
  public function getMustHitNote(strumlineSize:Int = 4):Bool
  {
    return getStrumlineIndex(strumlineSize) == 0;
  }

  /**
   * @param force Set to `true` to force recalculation (good after BPM changes)
   * @return The position of the note in the song, in steps.
   */
  public function getStepTime(force:Bool = false):Float
  {
    return rowTime / Constants.ROWS_PER_STEP;
  }

  /**
   * @param force Set to `true` to force recalculation (good after BPM changes)
   * @return The length of the hold note in steps, or `0` if this is not a hold note.
   */
  public function getStepLength(force = false):Float
  {
    if (this.length <= 0) return 0.0;

    return length / Constants.ROWS_PER_STEP;
  }

  public function clone():SongNoteDataRaw
  {
    return new SongNoteDataRaw(this.rowTime, this.data, this.length, this.kind);
  }

  public function toString():String
  {
    return 'SongNoteData(${this.rowTime} rows, ' + (this.length > 0 ? '[${this.length}ms hold]' : '') + ' ${this.data}'
      + (this.kind != '' ? ' [kind: ${this.kind}])' : ')');
  }
}

/**
 * Wrap SongNoteData in an abstract so we can overload operators.
 */
@:forward
abstract SongNoteData(SongNoteDataRaw) from SongNoteDataRaw to SongNoteDataRaw
{
  public function new(time:Int, data:Int, length:Int = 0, kind:String = '')
  {
    this = new SongNoteDataRaw(time, data, length, kind);
  }

  public static function buildDirectionName(data:Int, strumlineSize:Int = 4):String
  {
    switch (data % strumlineSize)
    {
      case 0:
        return 'Left';
      case 1:
        return 'Down';
      case 2:
        return 'Up';
      case 3:
        return 'Right';
      default:
        return 'Unknown';
    }
  }

  @:jignored
  public var isHoldNote(get, never):Bool;

  public function get_isHoldNote():Bool
  {
    return this.length > 0;
  }

  @:op(A == B)
  public function op_equals(other:SongNoteData):Bool
  {
    // Handle the case where one value is null.
    if (this == null) return other == null;
    if (other == null) return false;

    if (this.kind == null || this.kind == '')
    {
      if (other.kind != '' && this.kind != null) return false;
    }
    else
    {
      if (other.kind == '' || this.kind == null) return false;
    }

    return this.rowTime == other.rowTime && this.data == other.data && this.length == other.length;
  }

  @:op(A != B)
  public function op_notEquals(other:SongNoteData):Bool
  {
    // Handle the case where one value is null.
    if (this == null) return other == null;
    if (other == null) return false;

    if (this.kind == '')
    {
      if (other.kind != '') return true;
    }
    else
    {
      if (other.kind == '') return true;
    }

    return this.rowTime != other.rowTime || this.data != other.data || this.length != other.length;
  }

  @:op(A > B)
  public function op_greaterThan(other:SongNoteData):Bool
  {
    if (other == null) return false;

    return this.rowTime > other.rowTime;
  }

  @:op(A < B)
  public function op_lessThan(other:SongNoteData):Bool
  {
    if (other == null) return false;

    return this.rowTime < other.rowTime;
  }

  @:op(A >= B)
  public function op_greaterThanOrEquals(other:SongNoteData):Bool
  {
    if (other == null) return false;

    return this.rowTime >= other.rowTime;
  }

  @:op(A <= B)
  public function op_lessThanOrEquals(other:SongNoteData):Bool
  {
    if (other == null) return false;

    return this.rowTime <= other.rowTime;
  }

  public function clone():SongNoteData
  {
    return new SongNoteData(this.rowTime, this.data, this.length, this.kind);
  }

  /**
   * Produces a string representation suitable for debugging.
   */
  public function toString():String
  {
    return 'SongNoteData(${this.rowTime} rows, ' + (this.length > 0 ? '[${this.length} row hold]' : '') + ' ${this.data}'
      + (this.kind != '' ? ' [kind: ${this.kind}])' : ')');
  }
  public static function fromVSlice(conductor: LegacyConductor, raw: VSliceNoteData): SongNoteData {
    // : )
    final rowTime = conductor.getTimeInRows(raw.time);
    final rowLength = conductor.getTimeInRows(raw.time + raw.length) - rowTime;

    return new SongNoteData(rowTime, raw.data, rowLength, raw.kind);
  }
  public function toVSlice(conductor: Conductor): VSliceNoteData {
    final msTime = conductor.getRowTimeInMs(this.rowTime);
    final msLength = conductor.getRowTimeInMs(this.rowTime + this.length) - msTime;

    return new VSliceNoteData(msTime, this.data, msLength, this.kind);
  }
}

class ChartKey {
  public var difficulty: String;
  public var gamemode: String;

  public function new(difficulty:String, gamemode:String) {
    this.difficulty = difficulty;
    this.gamemode = gamemode;
  }
  // I hate you all
  public function hashCode(): Int {
    return difficulty.hashCode()*3 + gamemode.hashCode();
  }
  public function equals(that:ChartKey): Bool {
    return this.difficulty == that.difficulty && this.gamemode == that.gamemode;
  }
  public function toString(): String {
    return '${gamemode} - ${difficulty}';
  }
}
