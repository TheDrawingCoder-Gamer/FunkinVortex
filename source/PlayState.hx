package;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.display.FlxGridOverlay;
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
import haxe.ui.containers.dialogs.Dialog.DialogButton;
import haxe.ui.core.Component;
import haxe.ui.events.MouseEvent;
import haxe.ui.events.UIEvent;
import haxe.ui.focus.FocusManager;
import haxe.ui.macros.ComponentMacros;
import haxe.ui.styles.Style;
import haxe.ui.backend.flixel.UIState;
import openfl.media.Sound;
import vortex.data.song.SongData;
import vortex.data.song.SongData.SongCharts;
import vortex.data.song.SongData.SongNoteData;
import vortex.data.song.SongData.ChartKey;
import lime.ui.FileDialogType;
import sys.io.File;
import vortex.audio.FunkinSound;
import vortex.audio.VoicesGroup;

import vortex.data.song.VortexC;
import vortex.data.song.vslice.FNFC;
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

@:build(haxe.ui.macros.ComponentMacros.build("assets/exclude/data/main-view.xml"))
@:allow(SongDataEditor)
class PlayState extends UIState{
	public var songData:SongData = new SongData("test", "unknown");
	
	public var songId:String = "";
	public var selectedChart: ChartKey = new ChartKey("normal", Constants.DANCE_COUPLE);
	public var savePath: Null<String> = null;
	public var currentSongChart(get, never): SongChart;

	function get_currentSongChart(): SongChart {
		if (songData == null) return null;
		return songData.chart.charts.get(selectedChart);
	}
	
	var availableCharts(get, never):Array<ChartKey>;
	function get_availableCharts(): Array<ChartKey> {
		if (songData == null) return null;
		return songData.chart.charts.keys().array();
	}
	var chart:FlxSpriteGroup;
	//var staffLines:FlxSprite;
	var staffLineGroup:FlxTypedSpriteGroup<Line>;
	public var strumLine:FlxSpriteGroup;
	var curRenderedNotes:FlxTypedSpriteGroup<Note>;
	var curRenderedSus:FlxTypedSpriteGroup<SusNote>;
	var snaptext:FlxText;
	var curSnap:Float = 0;
	var curKeyType:Int = Normal;
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
	var curMeasureTxt:FlxText;
	var selectBox:FlxSprite;
	var toolInfo:FlxText;
	public var audioInstTrack:Null<FunkinSound> = null;
	public var audioVocalTrackGroup:VoicesGroup = new VoicesGroup();
	public var audioInstTrackData:Null<Bytes> = null;
	public var playerVocalTrackData:Null<Bytes> = null;
	public var oppVocalTrackData:Null<Bytes> = null;

	var snapInfo:Snaps = Four;
	var noteTypeText:FlxText;
	public var noteDisplayDirty: Bool = false;
	public var quantizationDirty: Bool = false;
	public var chartDirty: Bool = false;
	public var saveDataDirty: Bool = false;

	public static final infosFont: String = "Roboto Bold";

	var metadataToolbox:toolboxes.MetadataToolbox; 


	override public function create()
	{
		super.create();
		strumLine = new FlxSpriteGroup(0, 0);
		curRenderedNotes = new FlxTypedSpriteGroup<Note>();
		curRenderedSus = new FlxTypedSpriteGroup<SusNote>();
		// make it ridulously big
		// TODO: Camera scrolling
		// staffLines = new FlxSprite().makeGraphic(FlxG.width, 1000 * LINE_SPACING, FlxColor.BLACK);
		staffLineGroup = new FlxTypedSpriteGroup<Line>();
		staffLineGroup.setPosition(0, 0);
		generateStrumLine();
		strumLine.screenCenter(X);
		strumLine.x -= 250;

		metadataToolbox = new toolboxes.MetadataToolbox(this);
		buildFileMenu();
		buildChartMenu();
		buildWindowMenu();
		//staffLines.screenCenter(X);
		staffLineGroup.screenCenter(X);
		chart = new FlxSpriteGroup();
		//chart.add(staffLines);
		chart.add(staffLineGroup);
		chart.add(strumLine);
		chart.add(curRenderedSus);
		chart.add(curRenderedNotes);
		#if !electron
		FlxG.mouse.useSystemCursor = true;
		#end
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
		snaptext.font = infosFont;
		curMeasureTxt = new FlxText(200, FlxG.height, 0, 'Measure: 0', 16);
		curMeasureTxt.y -= curMeasureTxt.height;
		curMeasureTxt.scrollFactor.set();
		curMeasureTxt.font = infosFont;
		toolInfo = new FlxText(FlxG.width / 2, FlxG.height, 0, "a", 16);
		// don't immediately set text to '' because height??
		toolInfo.y -= toolInfo.height;
		toolInfo.text = 'hover over things to see what they do';
		noteTypeText = new FlxText(FlxG.width / 2, toolInfo.y, 0, "Normal Type", 16);
		noteTypeText.scrollFactor.set();
		noteTypeText.font = infosFont;
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
		add(curMeasureTxt);
		// add(openButton);

		add(noteTypeText);
		// add(saveButton);
		// add(loadVocalsButton);
		// add(loadInstButton);
		// add(toolInfo);
		// add(ui_box);
		add(selectBox);
		//add(haxeUIOpen);
	}



	private function loadFromFile():Void
	{
		var future = FNFAssets.askToBrowseForPath("vortexc", "Select Vortex Chart");
		future.onComplete(function(s:String)
		{
			try {
				final vortexc = VortexC.loadFromPath(s);
				loadFromVortexC(vortexc);
			} catch (e) {
				trace(e);
			}
			
		});
	}
	private function save(): Void {
		if (songData == null) return;
		if (savePath != null) {
			saveToPath(savePath);
		} else {
			saveAs();	
		}
	}
	private function saveAs(): Void {
		var future = FNFAssets.askToBrowseForPath("vortexc", "Save Chart To...", FileDialogType.SAVE);
		future.onComplete(function(s:String) {
			savePath = s;
			saveToPath(s);
		});
	}
	private function saveToPath(s:String): Void {
		final vortexc = toVortexC(); 
		vortexc.save(s);
	}
	private function loadFromVortexC(vortexc: VortexC): Void {
		try {
			songData = vortexc.songData;
			songId = vortexc.songId;
			audioInstTrackData = vortexc.instrumental;
			playerVocalTrackData = vortexc.playerVocals;
			oppVocalTrackData = vortexc.opponentVocals;
			Conductor.instance.mapTimeChanges(songData.timeChanges);
			selectedChart = songData.chart.defaultChart();
			reloadInstrumental();
			// songDataThingie.refreshUI(songData);
			metadataToolbox.refresh();
			noteDisplayDirty = true;
			chartDirty = true;
			saveDataDirty = false;
		} catch (e) {
			trace(e);
		}
	}
	private function toVortexC(): VortexC {
		return new VortexC(songId, songData, audioInstTrackData, playerVocalTrackData, oppVocalTrackData);
	}
	private function toFNFCSong(): FNFCSong {
		return toVortexC().toFNFCSong();
	}
	private function saveFNFC(): Void {
		final fnfc = FNFC.fromSong(toFNFCSong());
		final future = FNFAssets.askToBrowseForPath("fnfc", "Export FNFC To... ", FileDialogType.SAVE);
		future.onComplete(function(s:String) {
			fnfc.saveTo(s);
		});

	}
	private function buildFileMenu(): Void {
		
		saveChartMenu.onClick = function(e:MouseEvent)
		{
			// TODO: Dialog
			if (songData == null) return;
			try {
				save();
			} catch (e) {
				trace(e);
			}
				
		};
		saveAsChartMenu.onClick = function(e:MouseEvent)
		{
			if (songData == null) return;
			try {
				saveAs();
			} catch (e) {
				trace(e);
			}
		};

		openChartMenu.onClick = function(e:MouseEvent)
		{
			loadFromFile();
		};
		importFNFCMenu.onClick = function(e:MouseEvent)
		{
			importFromFNFC();
		};
		exportFNFCMenu.onClick = function(e:MouseEvent)
		{
			saveFNFC();	
		};	
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
		loadPlayerVoiceMenu.onClick = function(e:MouseEvent)
		{
			var future = FNFAssets.askToBrowseForPath("ogg", "Select Voice Track");
			future.onComplete(function(s:String)
			{
				playerVocalTrackData = File.getBytes(s);
				reloadInstrumental();
			});
		};
		loadOpponentVoiceMenu.onClick = function(e:MouseEvent)
		{
			var future = FNFAssets.askToBrowseForPath("ogg", "Select Voice Track");
			future.onComplete(function(s:String)
			{
				oppVocalTrackData = File.getBytes(s);
				reloadInstrumental();
			});
		};
	}
	private function buildChartMenu(): Void {
		prevChartMenu.onClick = function(e:MouseEvent) {
			changeDifficulty(false);
		};
		nextChartMenu.onClick = function(e:MouseEvent) {
			changeDifficulty(true);
		};
	}
	private function buildWindowMenu(): Void {
		toggleToolboxMetadata.onChange = function(event:UIEvent) {
			if (event.target.value) {
				metadataToolbox.showDialog(false);
			} else {
				metadataToolbox.hideDialog(DialogButton.CANCEL);
			}
		};
	}
	private function importFromFNFC(?variation:String): Void {
		if (variation == null) variation = Constants.DEFAULT_VARIATION;
		var future = FNFAssets.askToBrowseForPath("fnfc", "Select FNF Chart");
		future.onComplete(function(s:String)
		{
			try {
				final fnfc = FNFC.loadFromPath(s);
				// TODO: dialog
				if (fnfc == null) return;
				final fnfcSong = fnfc.getVariation(variation);
				if (fnfcSong == null) return;
				final vortexc = VortexC.fromFNFCSong(fnfcSong);
				loadFromVortexC(vortexc);
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
			audioInstTrack.stop();
			audioInstTrack.destroy();
			audioInstTrack = null;
		}
	}
	private function postLoadInstrumental():Void {
		if (audioInstTrack != null)
		{
		}
		else
		{
			trace('ERROR: Instrumental track is null!');
		}
		chartDirty = true;
	}
	private function playVocals(isDaddy: Bool): Bool {
		final track = if (isDaddy) oppVocalTrackData else playerVocalTrackData;
		final vocalTrack = SoundUtil.buildSoundFromBytes(track);

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

		return true;
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
			if (FlxG.keys.justPressed.F4)
			{
				changeDifficulty(false);
			} else if (FlxG.keys.justPressed.F5)
			{
				changeDifficulty(true);
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


		}
		handleMusicPlayback(elapsed);

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

	private function updateMeasure(): Void {
		curMeasureTxt.text = 'Measure: ${Conductor.instance.currentMeasureTime}';
	}
	private function moveStrumLine(change:Int = 0)
	{
		strumLine.y += change * curSnap;

		if (change != 0)
			strumLine.y = Math.round(strumLine.y / curSnap) * curSnap;
		var strumRow = getRow(strumLine.y);
		/*
		if (curSelectedNote != null)
		{
			curSelectedNote.length = strumTime - curSelectedNote.time;
			curSelectedNote.length = FlxMath.bound(curSelectedNote.length, 0);
		}
		*/
		if (curHoldSelect != null)
		{
			curHoldSelect.length = strumRow - curHoldSelect.rowTime;
			curHoldSelect.length = Std.int(FlxMath.bound(curHoldSelect.length, 0));
		}
		updateNotes();
		Conductor.instance.update(Conductor.instance.getRowTimeInMs(strumRow));
		updateMeasure();
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
		//for (item in staffLineGroup) {
		//	item.kill();
		//}
		var i = 0;
		var y = 0;
		var m = 0;
		while (y < bottom) {
			final time = getStrumTime(y);	
			final timeChange = Conductor.instance.timeChangeAt(time);

			final newMeasure:Bool = i % timeChange.stepsPerMeasure() == 0;
			var lineColor = newMeasure ? FlxColor.WHITE : FlxColor.GRAY;
			if (newMeasure) {
				i = 0;
			}
			var line = staffLineGroup.recycle(() -> new Line(Std.int(strumLine.width)));
			line.lineSprite.color = lineColor;
			line.x = strumLine.x;
			line.y = y;
			if (newMeasure)
				line.setText(Std.string(m));
		
			y += LINE_SPACING * 4;
			i += 4;
			if (newMeasure)
				m += 1;
		}
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
		if (currentSongChart?.notes == null) return;
		var noteRow = getRow(strumLine.members[id].y);
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
		var goodNote = new SongNoteData(noteRow, noteData, noteSus, noteKindName);
		// prefer overloading : )
		for (note in currentSongChart.notes)
		{
			if (note.rowTime == noteRow && note.data == noteData)
			{
				currentSongChart.notes.remove(note);
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
		currentSongChart.notes.push(goodNote);
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

	private function changeDifficulty(increase:Bool):Void {
		if (songData == null) return;
		var curIndex = availableCharts.indexOf(selectedChart);
		if (increase) {
			curIndex += 1;
		} else {
			curIndex -= 1;
		}
		curIndex = FlxMath.wrap(curIndex, 0, availableCharts.length - 1);

		selectedChart = availableCharts[curIndex];
		metadataToolbox.refresh();
		chartDirty = true;
		noteDisplayDirty = true;
	}

	private function deselectNote():Void
	{
		curSelectedNote = null;
		// sectionInfo.visible = true;
		// noteInfo.visible = false;
	}

	private function selectNote(id:Int):Void
	{
		if (songData == null) return;
		if (currentSongChart?.notes == null) return;
		var noteRow = getRow(strumLine.members[id].y);
		var noteData = id;

		for (note in currentSongChart.notes)
		{
			if (note.rowTime == noteRow && note.data == noteData)
			{
				curSelectedNote = note;
				// sectionInfo.visible = false;
				// noteInfo.visible = true;
				// noteInfo.updateNote(curSelectedNote);
				updateNotes();
				// updateNoteUI();
				// songDataThingie.refreshNoteUI(note);

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
		if (songData == null) return;
		if (currentSongChart?.notes == null) return;
		if (!noteDisplayDirty) return;

		noteDisplayDirty = false;
		var displayedNoteData: Array<SongNoteData> = [];


		for (noteSprite in curRenderedNotes.members) {
			if (noteSprite == null || noteSprite.noteData == null || !noteSprite.exists || !noteSprite.visible) continue;
			
			if (currentSongChart.notes.fastContains(noteSprite.noteData)) {
				displayedNoteData.push(noteSprite.noteData);
				noteSprite.updateNotePosition();
			} else {
				noteSprite.noteData = null;
			}
		}

		displayedNoteData.insertionSort((a, b) -> FlxSort.byValues(FlxSort.ASCENDING, a.rowTime, b.rowTime));

		var displayedHoldNoteData:Array<SongNoteData> = [];
		for (holdNoteSprite in curRenderedSus.members) {
			if (holdNoteSprite == null || holdNoteSprite.noteData == null || !holdNoteSprite.exists || !holdNoteSprite.visible) {
				continue;
			}
			
			if (!currentSongChart.notes.fastContains(holdNoteSprite.noteData) || holdNoteSprite.noteData.length == 0) {
				holdNoteSprite.kill();
			} else if (displayedHoldNoteData.fastContains(holdNoteSprite.noteData)) {
				holdNoteSprite.kill();
			} else {
				displayedHoldNoteData.push(holdNoteSprite.noteData);
				holdNoteSprite.updateHoldNotePosition();
			}
		}
		displayedHoldNoteData.insertionSort((a, b) -> FlxSort.byValues(FlxSort.ASCENDING, a.rowTime, b.rowTime));
		for (noteData in currentSongChart.notes) {
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

				holdNoteSprite.noteData = noteSprite.noteData;

				holdNoteSprite.sustainLength = noteSprite.noteData.length;

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
		return Conductor.instance.getRowTimeInMs(getRow(yPos));
	}
	// Get the nearest row
	private function getRow(yPos:Float): Int {
		return Math.round((yPos / LINE_SPACING) * Constants.ROWS_PER_STEP);
	}
	private function getYFromRow(row: Int): Float {
		return LINE_SPACING * row * Constants.ROWS_PER_STEP;
	}

	// AUDIO
	private function startAudioPlayback(): Void {
		if (audioInstTrack != null) {
			final audioPos = getStrumTime(strumLine.y);
			audioInstTrack.time = audioPos;
			audioInstTrack.play(false, audioPos);
			audioVocalTrackGroup.play(false, audioPos);
		}
	}
	private function stopAudioPlayback(): Void {
		if (audioInstTrack != null) audioInstTrack.pause();
		audioVocalTrackGroup.pause();
	}
	private function toggleAudioPlayback():Void {
		if (audioInstTrack == null) return;

		if (audioInstTrack.isPlaying) {
			stopAudioPlayback();
		} else {
			startAudioPlayback();
		}
	}
	private function handleMusicPlayback(elapsed:Float):Void {
		if (audioInstTrack != null) {
			audioInstTrack.update(elapsed);
			// If the song starts 50ms in, make sure we start the song there.
			if (Conductor.instance.instrumentalOffset < 0)
			{
				if (audioInstTrack.time < -Conductor.instance.instrumentalOffset)
				{
					trace('Resetting instrumental time to ${- Conductor.instance.instrumentalOffset}ms');
					audioInstTrack.time = -Conductor.instance.instrumentalOffset;
				}
			}
		}
		if (audioInstTrack != null && audioInstTrack.isPlaying) {
			Conductor.instance.update(audioInstTrack.time);
			strumLine.y = Conductor.instance.currentRowTime * LINE_SPACING / Constants.ROWS_PER_STEP;
			updateMeasure();
			if (Math.abs(audioInstTrack.time - audioVocalTrackGroup.time) > 100) {
				audioVocalTrackGroup.time = audioInstTrack.time;
			}
		}
		if (FlxG.keys.justPressed.SPACE && FocusManager.instance.focus == null) {
			toggleAudioPlayback();
		}
	}

}

class Line extends FlxSpriteGroup
{
	public final lineSprite:FlxSprite;
	public final text:FlxText;
	public function new(width: Int, ?x:Float = 0, ?y:Float = 0)
	{
		super(x, y);
		lineSprite = new FlxSprite(x, y).makeGraphic(width, 5, FlxColor.WHITE);
		text = new FlxText(x, y, 0, '', 30);
		text.x -= text.width + 20;
		text.y -= text.height / 2;
		text.font = "Roboto";
		add(lineSprite);
		add(text);
	}
	public function setText(value:String): Void {
		text.text = value;
		text.x = x - text.width - 20;
		text.y = y - text.height / 2;
	}
	override function set_x(value:Float):Float {
		final originX = (lineSprite?.x ?? x) - x;
		return super.set_x(value - originX);
	}
	override function set_y(value:Float):Float {
		final originY = (lineSprite?.y ?? y) - y;
		return super.set_y(value - originY); 
	}
}
