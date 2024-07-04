package;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUIState;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.weapon.FlxBullet;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxTileFrames;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.input.mouse.FlxMouseEventManager;
import flixel.math.FlxMath;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxSpriteUtil;
import flixel.math.FlxPoint;
import haxe.Json;
import haxe.ui.Toolkit;
import haxe.ui.components.Button;
import haxe.ui.components.CheckBox;
import haxe.ui.components.NumberStepper;
import haxe.ui.components.Stepper;
import haxe.ui.components.TextField;
import haxe.ui.containers.TabView;
import haxe.ui.containers.VBox;
import haxe.ui.containers.menus.Menu;
import haxe.ui.containers.menus.MenuBar;
import haxe.ui.containers.menus.MenuItem;
import haxe.ui.core.Component;
import haxe.ui.events.MouseEvent;
import haxe.ui.events.UIEvent;
import haxe.ui.focus.FocusManager;
import haxe.ui.macros.ComponentMacros;
import haxe.ui.styles.Style;
import openfl.media.Sound;
import vortex.data.song.SongData;
import vortex.data.song.SongData.SongChartData;
import vortex.data.song.SongData.SongNoteData;
import lime.ui.FileDialogType;
import sys.io.File;
import vortex.audio.FunkinSound;
import vortex.audio.VoicesGroup;

import vortex.data.song.VortexC;
import vortex.util.assets.SoundUtil;
import haxe.io.Bytes;

using StringTools;

// import bulbytools.Assets;

enum abstract Snaps(Int) from Int to Int
{
	var Four;
	var Eight;
	var Twelve;
	var Sixteen;
	//var Twenty;
	var TwentyFour;
	var ThirtyTwo;
	var FourtyEight;
	var SixtyFour;
	var NinetySix;
	var OneNineTwo;

	@:op(A == B) static function _(_, _):Bool;
}

enum abstract NoteTypes(Int) from Int to Int
{
	@:op(A == B) static function _(_, _):Bool;

	var Normal;
	var Lift;
	var Mine;
	var Death;
}

typedef HoldSelect = {
	var timeStamp: Float;
	var noteData: Int;
	var noteSus: Float;
};
// By default sections come in steps of 16.
// i should be using tab menu... oh well
// we don't have to worry about backspaces ^-^

@:allow(SongDataEditor)
class PlayState extends FlxUIState
{
	public var songData:SongData = null;
	
	public var songId:String = "";
	public var selectedDifficulty:String = "normal";
	var currentSongChartNotes(get, never):Array<SongNoteData>;

	function get_currentSongChartNotes(): Array<SongNoteData> {
		if (songData == null) return null;
		return songData.chart.notes[selectedDifficulty];
	}
	var chart:FlxSpriteGroup;
	var staffLines:FlxSprite;
	var staffLineGroup:FlxTypedSpriteGroup<Line>;
	var defaultLine:Line;
	public var strumLine:FlxSpriteGroup;
	var curRenderedNotes:FlxTypedSpriteGroup<Note>;
	var curRenderedSus:FlxTypedSpriteGroup<SusNote>;
	var snaptext:FlxText;
	var curSnap:Float = 0;
	var curKeyType:Int = Normal;
	var menuBar:MenuBar;
	var curSelectedNote:Null<SongNoteData> = null;
	var curHoldSelect:Null<SongNoteData> = null;
	public static final GRID_SIZE = 40;
	public static final LINE_SPACING: Int = 40;
	public static final STRUMLINE_SIZE: Int = 4;
	var camFollow:FlxObject;
	var lastLineY:Int = 0;
	var sectionMarkers:Array<Float> = [];
	var songLengthInSteps:Int = 0;
	var songSectionTimes:Array<Float> = [];
	var useLiftNote:Bool = false;
	var noteControls:Array<Bool> = [false, false, false, false, false, false, false, false];
	var noteRelease:Array<Bool> = [false, false, false, false, false, false, false, false];
	var noteHold:Array<Bool> = [false, false, false, false, false, false, false, false];
	var curSectionTxt:FlxText;
	var selectBox:FlxSprite;
	var toolInfo:FlxText;
	public var audioInstTrack:Null<FunkinSound> = null;
	public var vocalsGroup:VoicesGroup = new VoicesGroup();
	public var audioInstTrackData:Null<Bytes> = null;
	public var playerVocalTrackData:Null<Bytes> = null;
	public var oppVocalTrackData:Null<Bytes> = null;
	var songDataThingie:SongDataEditor;

	var snapInfo:Snaps = Four;
	var noteTypeText:FlxText;
	public var noteDisplayDirty: Bool = false;
	public var quantizationDirty: Bool = false;
	public var chartDirty: Bool = false;
	public var saveDataDirty: Bool = false;


	override public function create()
	{
		super.create();
		strumLine = new FlxSpriteGroup(0, 0);
		curRenderedNotes = new FlxTypedSpriteGroup<Note>();
		curRenderedSus = new FlxTypedSpriteGroup<SusNote>();
		// make it ridulously big
		// TODO: Camera scrolling
		staffLines = new FlxSprite().makeGraphic(FlxG.width, 1000 * LINE_SPACING, FlxColor.BLACK);
		staffLineGroup = new FlxTypedSpriteGroup<Line>();
		staffLineGroup.setPosition(0, 0);
		defaultLine = new Line();
		staffLineGroup.add(defaultLine);
		defaultLine.kill();
		generateStrumLine();
		strumLine.screenCenter(X);
		strumLine.x -= 250;

		staffLines.screenCenter(X);
		staffLineGroup.screenCenter(X);
		chart = new FlxSpriteGroup();
		chart.add(staffLines);
		chart.add(staffLineGroup);
		chart.add(strumLine);
		chart.add(curRenderedSus);
		chart.add(curRenderedNotes);
		#if !electron
		FlxG.mouse.useSystemCursor = true;
		#end
		// i think UIs in code get out of hand fast and i know others prefer it so.. - creator of the ui thing
		menuBar = new MenuBar();
		menuBar.customStyle.width = FlxG.width;
		var fileMenu = new Menu();
		fileMenu.text = "File";
		var saveChartMenu = new MenuItem();
		saveChartMenu.text = "Save Chart";
		saveChartMenu.onClick = function(e:MouseEvent)
		{
			// TODO: Dialog
			if (songData == null) return;
			var future = FNFAssets.askToBrowseForPath("vortexc", "Save Chart To...", FileDialogType.SAVE);
			future.onComplete(function(s: String) {

			});
		};
		var openChartMenu = new MenuItem();
		openChartMenu.text = "Open Chart";
		openChartMenu.onClick = function(e:MouseEvent)
		{
			loadFromFile();
		};
		var loadInstMenu = new MenuItem();
		loadInstMenu.text = "Load Instrument";
		loadInstMenu.onClick = function(e:MouseEvent)
		{
			var future = FNFAssets.askToBrowseForPath("ogg", "Select Instrument Track");
			future.onComplete(function(s:String)
			{
				try {
					audioInstTrackData = File.getBytes(s);
					reloadInstrumental();
					chartDirty = true;
					quantizationDirty = true;
				} catch (e) {
					trace(e);
				}
			});
		};
		var loadVoiceMenu = new MenuItem();
		loadVoiceMenu.text = "Load Player Vocals";
		loadVoiceMenu.onClick = function(e:MouseEvent)
		{
			var future = FNFAssets.askToBrowseForPath("ogg", "Select Voice Track");
			future.onComplete(function(s:String)
			{
				playerVocalTrackData = File.getBytes(s);
			});
		};
		/*
		var exportMenu = new MenuItem();
		exportMenu.text = "Export to base game";
		exportMenu.onClick = function(e:MouseEvent)
		{
			var cloneThingie = new Cloner();

			var sussySong:SwagSong = cloneThingie.clone(_song);
			for (i in 0...sussySong.notes.length)
			{
				for (j in 0...sussySong.notes[i].sectionNotes.length)
				{
					var noteThingie:Array<Dynamic> = sussySong.notes[i].sectionNotes[j];
					// remove lift info
					noteThingie[4] = null;
					if ((noteThingie[3] is Int))
					{
						if (noteThingie[3] > 0)
		noteThingie[3] = true;
						else
							noteThingie[3] = false;
					}
				}
				Reflect.deleteField(sussySong.notes[i], "altAnimNum");
			}
			var json = {
				"song": sussySong,
				"generatedBy": "FunkinVortexExport"
			};
			var data = Json.stringify(json);
			if ((data != null) && (data.length > 0))
				FNFAssets.askToSave("song", data);
		};
		*/
		fileMenu.addComponent(saveChartMenu);
		fileMenu.addComponent(openChartMenu);
		// fileMenu.addComponent(exportMenu);
		fileMenu.addComponent(loadInstMenu);
		fileMenu.addComponent(loadVoiceMenu);
		menuBar.addComponent(fileMenu);
		songDataThingie = new SongDataEditor(this);
		songDataThingie.x = FlxG.width / 2;
		songDataThingie.y = 100;
		// songDataThingie.refreshUI(songMetadata, songChartData);
		curSnap = LINE_SPACING * 4;
		drawChartLines();
		updateNotes();
		handleNotes();
		camFollow = new FlxObject(FlxG.width / 2, strumLine.getGraphicMidpoint().y);
		FlxG.camera.follow(camFollow, LOCKON);
		//staffLines.y += strumLine.height / 2;
			
		snaptext = new FlxText(0, FlxG.height, 0, '4ths', 24);
		snaptext.y -= snaptext.height;
		snaptext.scrollFactor.set();
		curSectionTxt = new FlxText(200, FlxG.height, 0, 'Section: 0', 16);
		curSectionTxt.y -= curSectionTxt.height;
		curSectionTxt.scrollFactor.set();
		toolInfo = new FlxText(FlxG.width / 2, FlxG.height, 0, "a", 16);
		// don't immediately set text to '' because height??
		toolInfo.y -= toolInfo.height;
		toolInfo.text = 'hover over things to see what they do';
		noteTypeText = new FlxText(FlxG.width / 2, toolInfo.y, 0, "Normal Type", 16);
		noteTypeText.scrollFactor.set();
		// NOT PIXEL PERFECT
		toolInfo.scrollFactor.set();
		selectBox = new FlxSprite().makeGraphic(1, 1, FlxColor.GRAY);
		selectBox.visible = false;
		selectBox.scrollFactor.set();
		// addUI();
		add(strumLine);
		add(curRenderedNotes);
		add(curRenderedSus);
		add(chart);
		add(snaptext);
		add(curSectionTxt);
		// add(openButton);

		add(menuBar);
		add(noteTypeText);
		// add(saveButton);
		// add(loadVocalsButton);
		// add(loadInstButton);
		// add(toolInfo);
		// add(ui_box);
		add(songDataThingie);
		add(selectBox);
		// add(haxeUIOpen);
	}



	private function loadFromFile():Void
	{
		var future = FNFAssets.askToBrowseForPath("vortexc", "Select Vortex Chart");
		future.onComplete(function(s:String)
		{
			try {
				final vortexc = VortexC.loadFromPath(s);
				songData = vortexc.songData;
				songId = vortexc.songId;
				audioInstTrackData = vortexc.instrumental;
				playerVocalTrackData = vortexc.playerVocals;
				oppVocalTrackData = vortexc.opponentVocals;
				reloadInstrumental();
				noteDisplayDirty = true;
				chartDirty = true;
				saveDataDirty = false;
			} catch (e) {
				trace(e);
			}
			
		});
	}

	private function playInstrumental(): Bool {
		final instTrack = SoundUtil.buildSoundFromBytes(audioInstTrackData);
		if (instTrack == null) return false;
		
		stopExistingInstrumental();
		audioInstTrack = instTrack;
		postLoadInstrumental();

		FlxG.sound.list.remove(instTrack);

		return true;

	}
	private function stopExistingInstrumental():Void
	{
		if (audioInstTrack != null)
		{
			FlxG.sound.music = null;
			audioInstTrack.stop();
			audioInstTrack.destroy();
			audioInstTrack = null;
		}
	}
	private function postLoadInstrumental():Void {
		if (audioInstTrack != null)
		{
			FlxG.sound.music = audioInstTrack;
		}
		else
		{
			trace('ERROR: Instrumental track is null!');
		}
		chartDirty = true;
	}
	private function playVocals(isDaddy: Bool): Bool {
		final track = if (isDaddy) oppVocalTrackData else playerVocalTrackData;
		final vocalTrack = SoundUtil.buildSoundsFromBytes(track);

		if (vocalTrack != null) {
			if (isDaddy) {
				audioVocalTrackGroup.addOpponentVoice(vocalTrack);
			} else {
				audioVocalTrackGroup.addPlayerVoice(vocalTrack);
			}
			return true;
		}

		return false;
	}
	// reloads the songs instrumental n stuff
	private function reloadInstrumental():Bool {
		var result = playInstrumental();
		if (!result) return false;

		stopExistingVocals();

		result = playVocals(false);

		result = playVocals(true);

		// refresh other bits
		chartDirty = true;
	}
	private function stopExistingVocals():Void {
		audioVocalTrackGroup.clear();
	}
	var selecting:Bool = false;

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		noteControls = [
			FlxG.keys.justPressed.ONE,
			FlxG.keys.justPressed.TWO,
			FlxG.keys.justPressed.THREE,
			FlxG.keys.justPressed.FOUR,
			FlxG.keys.justPressed.FIVE,
			FlxG.keys.justPressed.SIX,
			FlxG.keys.justPressed.SEVEN,
			FlxG.keys.justPressed.EIGHT
		];
		noteRelease = [
			FlxG.keys.justReleased.ONE,
			FlxG.keys.justReleased.TWO,
			FlxG.keys.justReleased.THREE,
			FlxG.keys.justReleased.FOUR,
			FlxG.keys.justReleased.FIVE,
			FlxG.keys.justReleased.SIX,
			FlxG.keys.justReleased.SEVEN,
			FlxG.keys.justReleased.EIGHT
		];
		noteHold = [
			FlxG.keys.pressed.ONE,
			FlxG.keys.pressed.TWO,
			FlxG.keys.pressed.THREE,
			FlxG.keys.pressed.FOUR,
			FlxG.keys.pressed.FIVE,
			FlxG.keys.pressed.SIX,
			FlxG.keys.pressed.SEVEN,
			FlxG.keys.pressed.EIGHT
		];
		if (FocusManager.instance.focus == null)
		{
			if (FlxG.keys.justPressed.UP || FlxG.mouse.wheel > 0)
			{
				moveStrumLine(-1);
			}
			else if (FlxG.keys.justPressed.DOWN || FlxG.mouse.wheel < 0)
			{
				moveStrumLine(1);
			}
			if (FlxG.keys.justPressed.Q)
			{
				curKeyType -= 1;
				curKeyType = cast FlxMath.wrap(curKeyType, 0, 99);
				switch (curKeyType)
				{
					case Normal:
						noteTypeText.text = "Normal Note";
					case Lift:
						noteTypeText.text = "Lift Note";
					case Mine:
						noteTypeText.text = "Mine Note";
					case Death:
						noteTypeText.text = "Death Note";
					case 4:
						// drain
						noteTypeText.text = "Drain Note";
					default:
						noteTypeText.text = 'Custom Note ${curKeyType - 4}';
				}
			}
			else if (FlxG.keys.justPressed.E)
			{
				curKeyType += 1;
				curKeyType = cast FlxMath.wrap(curKeyType, 0, 99);
				switch (curKeyType)
				{
					case Normal:
						noteTypeText.text = "Normal Note";
					case Lift:
						noteTypeText.text = "Lift Note";
					case Mine:
						noteTypeText.text = "Mine Note";
					case Death:
						noteTypeText.text = "Death Note";
					case 4:
						// drain
						noteTypeText.text = "Drain Note";
					default:
						noteTypeText.text = 'Custom Note ${curKeyType - 4}';
				}
			}
			if (FlxG.keys.justPressed.RIGHT)
			{
				changeSnap(true);
			}
			else if (FlxG.keys.justPressed.LEFT)
			{
				changeSnap(false);
			}
			if (FlxG.keys.justPressed.ESCAPE && curSelectedNote != null)
			{
				deselectNote();
			}
			if (FlxG.keys.justPressed.HOME)
			{
				strumLine.y = 0;
				moveStrumLine(0);
			}
			/*
				if (FlxG.keys.pressed.SHIFT && FlxG.mouse.justPressed)
				{
					selecting = true;
					selectBox.x = FlxG.mouse.screenX;
					selectBox.y = FlxG.mouse.screenY;
					selectBox.scale.x = 1;
					selectBox.scale.y = 1;
					selectBox.visible = true;
				}
				if (FlxG.mouse.justReleased && selecting)
				{
					selecting = false;
					selectBox.visible = false;
				}

				if (selecting)
				{
					selectBox.scale.x = selectBox.x - FlxG.mouse.screenX;
					selectBox.scale.y = selectBox.y - FlxG.mouse.screenY;
					selectBox.offset.x = (selectBox.x - FlxG.mouse.screenX) / 2;
					selectBox.offset.y = (selectBox.y - FlxG.mouse.screenY) / 2;
				}
			 */

			if (FlxG.keys.pressed.SHIFT && FlxG.mouse.justPressed)
			{
				if (FlxG.mouse.overlaps(curRenderedNotes))
				{
					for (note in curRenderedNotes.members)
					{
						if (FlxG.mouse.overlaps(note))
						{
							strumLine.y = note.y;
							var noteData = note.noteData.data;
							selectNote(noteData);
							break;
						}
					}
				}
			}
			if (FlxG.keys.pressed.CONTROL && FlxG.mouse.justPressed)
			{
				if (FlxG.mouse.overlaps(curRenderedNotes))
				{
					for (note in curRenderedNotes.members)
					{
						if (FlxG.mouse.overlaps(note))
						{
							strumLine.y = note.y;
							var noteData = note.noteData.data;
							addNote(noteData);
							break;
						}
					}
				}
			}
			/*
				if (curSelectedNote != null)
				{
					curSelectedNote[3] = Std.int(noteInfo.stepperAltNote.value);
			}*/
			if (FlxG.keys.justPressed.SPACE && FlxG.sound.music != null)
			{
				if (FlxG.sound.music.playing)
				{
					FlxG.sound.music.pause();
					if (vocalSound != null)
					{
						vocalSound.pause();
					}
				}
				else
				{
					FlxG.sound.music.time = getStrumTime(strumLine.y);
					FlxG.sound.music.play();
					if (vocalSound != null)
					{
						vocalSound.play();
					}
				}
			}
			if (FlxG.sound.music != null && FlxG.sound.music.playing)
			{
				strumLine.y = getYfromStrum(FlxG.sound.music.time);
				// curSectionTxt.text = 'Section: ' + getSussySectionFromY(strumLine.y);
				// sectionInfo.changeSection(getSussySectionFromY(strumLine.y));
				if (vocalSound != null && !CoolUtil.nearlyEquals(vocalSound.time, FlxG.sound.music.time, 2))
				{
					vocalSound.time = FlxG.sound.music.time;
				}
			}
		}

		for (i in 0...noteControls.length)
		{
			if (!noteControls[i] || FocusManager.instance.focus != null)
				continue;
			if (FlxG.keys.pressed.CONTROL)
			{
				selectNote(i);
			}
			/*
			else if (FlxG.keys.pressed.A)
			{
				convertToRoll(i);
			}
			*/
			else
			{
				addNote(i);
			}
		}
		for (i in 0...noteRelease.length)
		{
			if (!noteRelease[i])
				continue;
			if (curHoldSelect != null && curHoldSelect.data == i)
			{
				curHoldSelect = null;
			}
		}
		handleNotes();
		handleQuantization();
		handleChart();
		camFollow.setPosition(FlxG.width / 2, strumLine.y);
	}

	private function moveStrumLine(change:Int = 0)
	{
		strumLine.y += change * curSnap;

		if (change != 0)
			strumLine.y = Math.round(strumLine.y / curSnap) * curSnap;
		var strumTime = getStrumTime(strumLine.y);
		/*
		if (curSelectedNote != null)
		{
			curSelectedNote.length = strumTime - curSelectedNote.time;
			curSelectedNote.length = FlxMath.bound(curSelectedNote.length, 0);
		}
		*/
		if (curHoldSelect != null)
		{
			curHoldSelect.length = strumTime - curHoldSelect.time;
			curHoldSelect.length = FlxMath.bound(curHoldSelect.length, 0);
		}
		updateNotes();
		// curSectionTxt.text = 'Measure: ' + Conductor.instance.timeChangeAt(strumTime).stepsPerMeasure();
	}

	private function generateStrumLine()
	{
		final graphic = FlxGraphic.fromAssetKey('assets/images/arrow.png');
		var frames = FlxTileFrames.fromGraphic(graphic, new FlxPoint(16, 16));
		for (i in 0...8)
		{
			var babyArrow = new FlxSprite(strumLine.x, strumLine.y);
			babyArrow.frames = frames;

			babyArrow.animation.add('tapNote', [3]);
			babyArrow.animation.play("tapNote");
			babyArrow.angle = switch (i % 4)
			{
				case 0:
					90;
				case 1:
					0;
				case 2:
					180;
				case 3:
					-90;
				default: 0;
			}
			babyArrow.antialiasing = false;
			babyArrow.setGraphicSize(Std.int(40));
			babyArrow.x += 45 * i;
			babyArrow.updateHitbox();
			babyArrow.scrollFactor.set();
			babyArrow.ID = i;
			strumLine.add(babyArrow);
		}
	}


	private function drawChartLines()
	{
		if (audioInstTrack == null) return;
		final bottom = getYfromStrum(audioInstTrack.length);
		staffLines.makeGraphic(FlxG.width, Std.int(bottom) + 10, FlxColor.BLACK);
		//for (item in staffLineGroup) {
		//	item.kill();
		//}
		var i = 0;
		var y = 0;
		while (y < bottom) {
			final time = getStrumTime(y);	
			final timeChange = Conductor.instance.timeChangeAt(time);
			var lineColor = i % timeChange.stepsPerMeasure() == 0 ? FlxColor.WHITE : FlxColor.GRAY;
			if (i % timeChange.stepsPerMeasure() == 0) {
				i = 0;
			}
			FlxSpriteUtil.drawLine(staffLines, FlxG.width * -0.5, y, FlxG.width * 1.5, y,
					{color: lineColor,
						thickness: 5});
			/*
			var line = staffLineGroup.recycle(() -> new Line());
			line.color = lineColor;

			line.setGraphicSize(Std.int(strumLine.width), 5);

			line.updateHitbox();
			line.x = strumLine.x;
			line.y = y;
			*/
		
			y += LINE_SPACING * 4;
			i += 4;
		}
	}
	function refreshChart() {

	}
	/*
	function convertToRoll(id:Int)
	{
		selectNote(id);
		var sections = [];
		// nothing fancy, just generate rolls
		if (curSelectedNote != null)
		{
			if (curSelectedNote[2] > 0)
			{
				for (sussy in 0...Math.floor(curSelectedNote[2] / Conductor.stepCrochet))
				{
					var goodSection = getSussySectionFromY(getSussyYPos(curSelectedNote[0] + sussy * Conductor.stepCrochet));
					sections.push(goodSection);
					var noteData = id;
					if (_song.notes[goodSection].mustHitSection)
					{
						var sussyInfo = 0;
						if (noteData > 3)
						{
							sussyInfo = noteData % 4;
						}
						else
						{
							sussyInfo = noteData + 4;
						}
						noteData = sussyInfo;
					}
					_song.notes[goodSection].sectionNotes.push([
						curSelectedNote[0] + sussy * Conductor.stepCrochet,
						noteData,
						0,
						curSelectedNote[3],
						curSelectedNote[4]
					]);
				}
			}
			curSelectedNote[2] = 0;
		}
		deselectNote();
		updateNotes(sections);
	}
	*/

	private function addNote(id:Int):Void
	{
		if (songData == null) return;
		var noteStrum = getStrumTime(strumLine.members[id].y);
		var noteData = id;
		var noteSus = 0;
		var noteKindName: Null<String> = 
			switch (curKeyType) {
				case Lift: "lift";
				case Mine: "mine";
				case Death: "nuke";
				case Normal: '';
				// TODO
				case key: Std.string(key);
			};
		var goodNote = new SongNoteData(noteStrum, noteData, noteSus, noteKindName);
		// prefer overloading : )
		for (note in songChartData.notes[selectedDifficulty])
		{
			if (CoolUtil.truncateFloat(note.time, 1) == CoolUtil.truncateFloat(noteStrum, 1) && note.data == noteData)
			{
				songChartData.notes[selectedDifficulty].remove(note);
				/*
				if (note.kind != noteKindName && )
				{
					break;
				}
				*/
				updateNotes();
				return;
			}
		}		
		currentSongChartNotes.push(goodNote);
		curHoldSelect = goodNote;
		updateNotes();
	}

	private function changeSnap(increase:Bool)
	{
		// i have no idea why it isn't throwing a hissy fit. Let's keep it that way.
		if (increase)
		{
			snapInfo += 1;
		}
		else
		{
			snapInfo -= 1;
		}
		snapInfo = cast FlxMath.wrap(cast snapInfo, 0, cast(OneNineTwo));
		switch (snapInfo)
		{
			case Four:
				snaptext.text = '4ths';
				curSnap = (LINE_SPACING * 16) / 4;
			case Eight:
				snaptext.text = '8ths';
				curSnap = (LINE_SPACING * 16) / 8;
			case Twelve:
				snaptext.text = '12ths';
				curSnap = (LINE_SPACING * 16) / 12;
			case Sixteen:
				snaptext.text = '16ths';
				curSnap = (LINE_SPACING * 16) / 16;
			//case Twenty:
			//	snaptext.text = '20ths';
			//	curSnap = (LINE_SPACING * 16) / 20;
			case TwentyFour:
				snaptext.text = '24ths';
				curSnap = (LINE_SPACING * 16) / 24;
			case ThirtyTwo:
				snaptext.text = '32nds';
				curSnap = (LINE_SPACING * 16) / 32;
			case FourtyEight:
				snaptext.text = '48ths';
				curSnap = (LINE_SPACING * 16) / 48;
			case SixtyFour:
				snaptext.text = '64ths';
				curSnap = (LINE_SPACING * 16) / 64;
			case NinetySix:
				snaptext.text = '96ths';
				curSnap = (LINE_SPACING * 16) / 96;
			case OneNineTwo:
				snaptext.text = '192nds';
				curSnap = (LINE_SPACING * 16) / 192;
		}
	}

	private function deselectNote():Void
	{
		curSelectedNote = null;
		// sectionInfo.visible = true;
		// noteInfo.visible = false;
	}

	private function selectNote(id:Int):Void
	{
		var noteStrum = getStrumTime(strumLine.members[id].y);
		var noteData = id;

		for (note in current)
		{
			if (CoolUtil.truncateFloat(note.time, 1) == CoolUtil.truncateFloat(noteStrum, 1) && note.data == noteData)
			{
				curSelectedNote = note;
				// sectionInfo.visible = false;
				// noteInfo.visible = true;
				// noteInfo.updateNote(curSelectedNote);
				updateNotes();
				// updateNoteUI();
				songDataThingie.refreshNoteUI(note);
				return;
			}
		}
	}

	@:deprecated
	public function getGoodInfo(noteData:Int)
	{
		return noteData;
	}
	private function handleQuantization(): Void {
		if (!quantizationDirty) return;

		quantizationDirty = false;

		for (noteSprite in curRenderedNotes.members) {
			if (noteSprite == null || noteSprite.noteData == null || !noteSprite.exists || !noteSprite.visible) continue;
			
			noteSprite.playNoteAnimation();
		}
	}
	private function handleChart(): Void {
		if (!chartDirty) return;

		chartDirty = false;

		drawChartLines();
	}
	public function updateNotes(): Void {
		noteDisplayDirty = true;
	}
	private function handleNotes(): Void
	{
		if (!noteDisplayDirty) return;

		noteDisplayDirty = false;
		var displayedNoteData: Array<SongNoteData> = [];


		for (noteSprite in curRenderedNotes.members) {
			if (noteSprite == null || noteSprite.noteData == null || !noteSprite.exists || !noteSprite.visible) continue;
			
			if (currentSongChartNotes.fastContains(noteSprite.noteData)) {
				displayedNoteData.push(noteSprite.noteData);
				noteSprite.updateNotePosition();
			} else {
				noteSprite.noteData = null;
			}
		}

		displayedNoteData.insertionSort((a, b) -> FlxSort.byValues(FlxSort.ASCENDING, a.time, b.time));

		var displayedHoldNoteData:Array<SongNoteData> = [];
		for (holdNoteSprite in curRenderedSus.members) {
			if (holdNoteSprite == null || holdNoteSprite.noteData == null || !holdNoteSprite.exists || !holdNoteSprite.visible) {
				continue;
			}
			
			if (!currentSongChartNotes.fastContains(holdNoteSprite.noteData) || holdNoteSprite.noteData.length == 0) {
				holdNoteSprite.kill();
			} else if (displayedHoldNoteData.fastContains(holdNoteSprite.noteData)) {
				holdNoteSprite.kill();
			} else {
				displayedHoldNoteData.push(holdNoteSprite.noteData);
				holdNoteSprite.updateHoldNotePosition();
			}
		}
		displayedHoldNoteData.insertionSort((a, b) -> FlxSort.byValues(FlxSort.ASCENDING, a.time, b.time));
		for (noteData in currentSongChartNotes) {
			if (noteData == null) continue;

			if (displayedNoteData.fastContains(noteData)) {
				continue;
			}

			var noteSprite = curRenderedNotes.recycle(() -> new Note(this));

			noteSprite.parentState = this;

			noteSprite.noteData = noteData;

			if (noteSprite.noteData != null 
				&&  noteSprite.noteData.length > 0
				&& !displayedHoldNoteData.contains(noteSprite.noteData)
				) {
				final holdNoteSprite = curRenderedSus.recycle(() -> new SusNote(this));
				noteSprite.childSus = holdNoteSprite;
				var noteLengthPixels = noteSprite.noteData.getStepLength() * LINE_SPACING;

				holdNoteSprite.noteData = noteSprite.noteData;

				holdNoteSprite.setHeightDirectly(noteLengthPixels);

				holdNoteSprite.updateHoldNotePosition();
				noteSprite.playNoteAnimation();
			}
		}
	}

	// kind of cursed
	private function getYfromStrum(strumTime:Float):Float
	{
		return LINE_SPACING * Conductor.instance.getTimeInSteps(strumTime);
	}

	private function getStrumTime(yPos:Float):Float
	{
		return Conductor.instance.getStepTimeInMs(yPos / LINE_SPACING);
	}
	// Get the nearest row
	private function getRow(yPos:Float): Int {
		return Math.round((yPos / LINE_SPACING) * Constants.ROWS_PER_STEP);
	}
	private function getYFromRow(row: Int): Float {
		LINE_SPACING * row * Constants.ROWS_PER_STEP;
	}

}

class Line extends FlxSprite
{
	public function new(?x:Float = 0, ?y:Float = 0)
	{
		super(x, y);
		makeGraphic(FlxG.width, 5, FlxColor.WHITE);
	}
}
