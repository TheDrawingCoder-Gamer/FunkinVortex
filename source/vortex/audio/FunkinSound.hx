package vortex.audio;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.sound.FlxSound;
import flixel.system.FlxAssets.FlxSoundAsset;
import flixel.tweens.FlxTween;
import flixel.util.FlxSignal.FlxTypedSignal;
// import funkin.audio.waveform.WaveformData;
// import funkin.audio.waveform.WaveformDataParser;
import vortex.util.ICloneable;
import openfl.Assets;
import lime.app.Future;
import lime.app.Promise;
import openfl.media.SoundMixer;

#if (openfl >= "8.0.0")
#end

/**
 * A FlxSound which adds additional functionality:
 * - Delayed playback via negative song position.
 * - Easy functions for immediate playback and recycling.
 */
@:nullSafety
class FunkinSound extends FlxSound implements ICloneable<FunkinSound>
{
  static final MAX_VOLUME:Float = 1.0;

  /**
   * An FlxSignal which is dispatched when the volume changes.
   */
  public static var onVolumeChanged(get, never):FlxTypedSignal<Float->Void>;

  static var _onVolumeChanged:Null<FlxTypedSignal<Float->Void>> = null;

  static function get_onVolumeChanged():FlxTypedSignal<Float->Void>
  {
    if (_onVolumeChanged == null)
    {
      _onVolumeChanged = new FlxTypedSignal<Float->Void>();
      FlxG.sound.volumeHandler = function(volume:Float) {
        _onVolumeChanged.dispatch(volume);
      }
    }
    return _onVolumeChanged;
  }

  /**
   * Using `FunkinSound.load` will override a dead instance from here rather than creating a new one, if possible!
   */
  static var pool(default, null):FlxTypedGroup<FunkinSound> = new FlxTypedGroup<FunkinSound>();

  /**
   * Calculate the current time of the sound.
   * NOTE: You need to `add()` the sound to the scene for `update()` to increment the time.
   */
  //
  public var muted(default, set):Bool = false;

  function set_muted(value:Bool):Bool
  {
    if (value == muted) return value;
    muted = value;
    updateTransform();
    return value;
  }

  override function set_volume(value:Float):Float
  {
    // Uncap the volume.
    _volume = FlxMath.bound(value, 0.0, MAX_VOLUME);
    updateTransform();
    return _volume;
  }

  public var paused(get, never):Bool;

  function get_paused():Bool
  {
    return this._paused;
  }

  public var isPlaying(get, never):Bool;

  function get_isPlaying():Bool
  {
    return this.playing || this._shouldPlay;
  }
  
  /**
   * Waveform data for this sound.
   * This is lazily loaded, so it will be built the first time it is accessed.
   */
  /**
  public var waveformData(get, never):WaveformData;

  var _waveformData:Null<WaveformData> = null;

  function get_waveformData():WaveformData
  {
    if (_waveformData == null)
    {
      _waveformData = WaveformDataParser.interpretFlxSound(this);
      if (_waveformData == null) throw 'Could not interpret waveform data!';
    }
    return _waveformData;
  }
  */
  /**
   * Are we in a state where the song should play but time is negative?
   */
  var _shouldPlay:Bool = false;

  /**
   * For debug purposes.
   */
  var _label:String = "unknown";

  /**
   * Whether we received a focus lost event.
   */
  var _lostFocus:Bool = false;

  public function new()
  {
    super();
  }

  public override function update(elapsedSec:Float)
  {
    if (!playing && !_shouldPlay) return;

    if (_time < 0)
    {
      var elapsedMs = elapsedSec * Constants.MS_PER_SEC;
      _time += elapsedMs;
      if (_time >= 0)
      {
        super.play();
        _shouldPlay = false;
      }
    }
    else
    {
      super.update(elapsedSec);
    }
  }

  public function togglePlayback():FunkinSound
  {
    if (playing)
    {
      pause();
    }
    else
    {
      resume();
    }
    return this;
  }

  public override function play(forceRestart:Bool = false, startTime:Float = 0, ?endTime:Float):FunkinSound
  {
    if (!exists) return this;

    if (forceRestart)
    {
      cleanup(false, true);
    }
    else if (playing)
    {
      return this;
    }

    if (startTime < 0)
    {
      this.active = true;
      this._shouldPlay = true;
      this._time = startTime;
      this.endTime = endTime;
      return this;
    }
    else
    {
      if (_paused)
      {
        resume();
      }
      else
      {
        startSound(startTime);
      }

      this.endTime = endTime;
      return this;
    }
  }

  public override function pause():FunkinSound
  {
    if (_shouldPlay)
    {
      // This sound will eventually play, but is still at a negative timestamp.
      // Manually set the paused flag to ensure proper focus/unfocus behavior.
      _shouldPlay = false;
      _paused = true;
      active = false;
    }
    else
    {
      super.pause();
    }
    return this;
  }

  /**
   * Called when the user clicks to focus on the window.
   */
  override function onFocus():Void
  {
    // Flixel can sometimes toss spurious `onFocus` events, e.g. if the Flixel debugger is toggled
    // on and off. We only want to resume the sound if we actually lost focus, and if we weren't
    // already paused before we lost focus.
    if (_lostFocus && !_alreadyPaused)
    {
      // trace('Resuming audio (${this._label}) on focus!');
      resume();
    }
    else
    {
      // trace('Not resuming audio (${this._label}) on focus!');
    }
    _lostFocus = false;
  }

  /**
   * Called when the user tabs away from the window.
   */
  override function onFocusLost():Void
  {
    // trace('Focus lost, pausing audio!');
    _lostFocus = true;
    _alreadyPaused = _paused;
    pause();
  }

  public override function resume():FunkinSound
  {
    if (this._time < 0)
    {
      // Sound with negative timestamp, restart the timer.
      _shouldPlay = true;
      _paused = false;
      active = true;
    }
    else
    {
      super.resume();
    }
    return this;
  }

  /**
   * Call after adjusting the volume to update the sound channel's settings.
   */
  @:allow(flixel.sound.FlxSoundGroup)
  override function updateTransform():Void
  {
    if (_transform != null)
    {
      _transform.volume = #if FLX_SOUND_SYSTEM ((FlxG.sound.muted || this.muted) ? 0 : 1) * FlxG.sound.volume * #end
        (group != null ? group.volume : 1) * _volume * _volumeAdjust;
    }

    if (_channel != null)
    {
      _channel.soundTransform = _transform;
    }
  }

  public function clone():FunkinSound
  {
    var sound:FunkinSound = new FunkinSound();

    // Clone the sound by creating one with the same data buffer.
    // Reusing the `Sound` object directly causes issues with playback.
    @:privateAccess
    sound._sound = openfl.media.Sound.fromAudioBuffer(this._sound.__buffer);

    // Call init to ensure the FlxSound is properly initialized.
    sound.init(this.looped, this.autoDestroy, this.onComplete);

    // Oh yeah, the waveform data is the same too!
    // @:privateAccess
    // sound._waveformData = this._waveformData;

    return sound;
  }

  /**
   * Creates a new `FunkinSound` object synchronously.
   *
   * @param embeddedSound   The embedded sound resource you want to play.  To stream, use the optional URL parameter instead.
   * @param volume          How loud to play it (0 to 1).
   * @param looped          Whether to loop this sound.
   * @param group           The group to add this sound to.
   * @param autoDestroy     Whether to destroy this sound when it finishes playing.
   *                          Leave this value set to `false` if you want to re-use this `FunkinSound` instance.
   * @param autoPlay        Whether to play the sound immediately or wait for a `play()` call.
   * @param onComplete      Called when the sound finished playing.
   * @param onLoad          Called when the sound finished loading.  Called immediately for succesfully loaded embedded sounds.
   * @return A `FunkinSound` object, or `null` if the sound could not be loaded.
   */
  public static function load(embeddedSound:FlxSoundAsset, volume:Float = 1.0, looped:Bool = false, autoDestroy:Bool = false, autoPlay:Bool = false,
      ?onComplete:Void->Void, ?onLoad:Void->Void):Null<FunkinSound>
  {
    @:privateAccess
    if (SoundMixer.__soundChannels.length >= SoundMixer.MAX_ACTIVE_CHANNELS)
    {
      FlxG.log.error('FunkinSound could not play sound, channels exhausted! Found ${SoundMixer.__soundChannels.length} active sound channels.');
      return null;
    }

    var sound:FunkinSound = pool.recycle(construct);

    // Load the sound.
    // Sets `exists = true` as a side effect.
    sound.loadEmbedded(embeddedSound, looped, autoDestroy, onComplete);

    if (embeddedSound is String)
    {
      sound._label = embeddedSound;
    }
    else
    {
      sound._label = 'unknown';
    }

    if (autoPlay) sound.play();
    sound.volume = volume;
    sound.group = FlxG.sound.defaultSoundGroup;
    sound.persist = true;

    // Make sure to add the sound to the list.
    // If it's already in, it won't get re-added.
    // If it's not in the list (it gets removed by FunkinSound.playMusic()),
    // it will get re-added (then if this was called by playMusic(), removed again)
    FlxG.sound.list.add(sound);

    // Call onLoad() because the sound already loaded
    if (onLoad != null && sound._sound != null) onLoad();

    return sound;
  }


  @:nullSafety(Off)
  public override function destroy():Void
  {
    // trace('[FunkinSound] Destroying sound "${this._label}"');
    super.destroy();
    if (fadeTween != null)
    {
      fadeTween.cancel();
      fadeTween = null;
    }
    FlxTween.cancelTweensOf(this);
    this._label = 'unknown';
  }

  /**
   * Play a sound effect once, then destroy it.
   * @param key
   * @param volume
   * @return static function construct():FunkinSound
   */
  public static function playOnce(key:String, volume:Float = 1.0, ?onComplete:Void->Void, ?onLoad:Void->Void):Void
  {
    var result = FunkinSound.load(key, volume, false, true, true, onComplete, onLoad);
  }

  /**
   * Stop all sounds in the pool and allow them to be recycled.
   */
  public static function stopAllAudio(musicToo:Bool = false):Void
  {
    for (sound in pool)
    {
      if (sound == null) continue;
      if (!musicToo && sound == FlxG.sound.music) continue;
      sound.destroy();
    }
  }

  static function construct():FunkinSound
  {
    var sound:FunkinSound = new FunkinSound();

    pool.add(sound);
    FlxG.sound.list.add(sound);

    return sound;
  }
}

/**
 * Additional parameters for `FunkinSound.playMusic()`
 */
typedef FunkinSoundPlayMusicParams =
{
  /**
   * The volume you want the music to start at.
   * @default `1.0`
   */
  var ?startingVolume:Float;

  /**
   * The suffix of the music file to play. Usually for "-erect" tracks when loading an INST file
   * @default ``
   */
  var ?suffix:String;

  /**
   * Whether to override music if a different track is already playing.
   * @default `false`
   */
  var ?overrideExisting:Bool;

  /**
   * Whether to override music if the same track is already playing.
   * @default `false`
   */
  var ?restartTrack:Bool;

  /**
   * Whether the music should loop or play once.
   * @default `true`
   */
  var ?loop:Bool;

  /**
   * Whether to check for `SongMusicData` to update the Conductor with.
   * @default `true`
   */
  var ?mapTimeChanges:Bool;

  /**
   * Which Paths function to use to load a song
   * @default `MUSIC`
   */
  //var ?pathsFunction:PathsFunction;

  var ?partialParams:PartialSoundParams;

  var ?onComplete:Void->Void;
  var ?onLoad:Void->Void;
}

typedef PartialSoundParams =
{
  var loadPartial:Bool;
  var start:Float;
  var end:Float;
}

