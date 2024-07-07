package;

import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.frames.FlxTileFrames;
import flixel.math.FlxPoint;
import vortex.data.song.SongData.SongNoteData;
import vortex.data.song.SongDataUtils;
import flixel.math.FlxMath;

@:nullSafety
class SusNote extends SustainTrail
{
  public var parentState:PlayState;
  public var colorswap: ColorSwapShader.ColorSwap;

  public function new(parent:PlayState)
  {

    super(0, 100);

    this.parentState = parent;
    this.colorswap = new ColorSwapShader.ColorSwap();
    this.shader = colorswap.shader;

    zoom = 1.0;

    flipY = false;
    antialiasing = false;

    setup();
  }

  public override function updateHitbox():Void
  {
    // Expand the clickable hitbox to the full column width, then nudge to the left to re-center it.
    width = PlayState.LINE_SPACING;
    height = graphicHeight;

    var xOffset = (PlayState.LINE_SPACING - graphicWidth) / 2;
    offset.set(-xOffset, 0);
    origin.set(width * 0.5, height * 0.5);
  }


  #if FLX_DEBUG
  /**
   * Call this to override how debug bounding boxes are drawn for this sprite.
   */
  public override function drawDebugOnCamera(camera:flixel.FlxCamera):Void
  {
    if (!camera.visible || !camera.exists || !isOnScreen(camera)) return;

    var rect = getBoundingBox(camera);
    trace('hold note bounding box: ' + rect.x + ', ' + rect.y + ', ' + rect.width + ', ' + rect.height);

    var gfx = beginDrawDebug(camera);
    debugBoundingBoxColor = 0xffFF66FF;
    gfx.lineStyle(2, color, 0.5); // thickness, color, alpha
    gfx.drawRect(rect.x, rect.y, rect.width, rect.height);
    endDrawDebug(camera);
  }
  #end

  function setup():Void
  {
    strumTime = 999999999;
    missedNote = false;
    hitNote = false;
    active = true;
    visible = true;
    alpha = 1.0;
    graphicWidth = graphic.width * zoom; // amount of notes * 2

    updateHitbox();
    
  }

  public override function revive():Void
  {
    super.revive();

    setup();
  }

  public override function kill():Void
  {
    super.kill();

    active = false;
    visible = false;
    noteData = null;
    strumTime = 999999999;
    sustainLength = 0;
    fullSustainLength = 0;
  }

  /**
   * Return whether this note is currently visible.
   */
  public function isHoldNoteVisible(viewAreaBottom:Float, viewAreaTop:Float):Bool
  {
    // True if the note is above the view area.
    var aboveViewArea = (this.y + this.height < viewAreaTop);

    // True if the note is below the view area.
    var belowViewArea = (this.y > viewAreaBottom);

    return !aboveViewArea && !belowViewArea;
  }

  /**
   * Return whether a hold note, if placed in the scene, would be visible.
   */
  public static function wouldHoldNoteBeVisible(viewAreaBottom:Float, viewAreaTop:Float, noteData:SongNoteData, ?origin:FlxObject):Bool
  {
    var noteHeight:Float = noteData.getStepLength() * PlayState.LINE_SPACING;
    var stepTime:Float = inline noteData.getStepTime();
    var notePosY:Float = stepTime * PlayState.LINE_SPACING;
    if (origin != null) notePosY += origin.y;

    // True if the note is above the view area.
    var aboveViewArea = (notePosY + noteHeight < viewAreaTop);

    // True if the note is below the view area.
    var belowViewArea = (notePosY > viewAreaBottom);

    return !aboveViewArea && !belowViewArea;
  }

  public function updateHoldNotePosition(?origin:FlxObject):Void
  {
    if (this.noteData == null) return;

    var cursorColumn:Int = this.noteData.data;

    if (cursorColumn < 0) cursorColumn = 0;
    if (cursorColumn >= (PlayState.STRUMLINE_SIZE * 2 + 1))
    {
      cursorColumn = (PlayState.STRUMLINE_SIZE * 2 + 1);

    }

    this.x = parentState.strumLine.members[cursorColumn].x;

    // Notes far in the song will start far down, but the group they belong to will have a high negative offset.
    // noteData.getStepTime() returns a calculated value which accounts for BPM changes
    var stepTime:Float =
    inline this.noteData.getStepTime();
    if (stepTime >= 0)
    {
      // Add epsilon to fix rounding issues?
      // var roundedStepTime:Float = Math.floor((stepTime + 0.01) / noteSnapRatio) * noteSnapRatio;
      this.y = stepTime * PlayState.GRID_SIZE;
    }

    this.x += PlayState.GRID_SIZE / 2;
    this.x -= this.graphicWidth / 2;

    this.y += PlayState.GRID_SIZE / 2;

    if (origin != null)
    {
      this.x += origin.x;
      this.y += origin.y;
    }

    // Account for expanded clickable hitbox.
    this.x += this.offset.x;

    // freaky...
    if (this.noteData.isRoll)
      colorswap.hue = 120 / 360;
    else
      colorswap.hue = 240 / 360;
  } 
}
