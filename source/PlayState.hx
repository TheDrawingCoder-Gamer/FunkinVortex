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
import vortex.data.song.SongData.SongEventData;
import vortex.data.song.SongData.ChartKey;
import lime.ui.FileDialogType;
import sys.io.File;
import vortex.audio.FunkinSound;
import vortex.audio.VoicesGroup;

import vortex.data.song.VortexC;
import vortex.data.song.vslice.FNFC;
import vortex.util.assets.SoundUtil;
import haxe.io.Bytes;
import vortex.data.song.Gamemode;
import vortex.util.SortUtil;

using vortex.data.song.SM;
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
class PlayState extends UIState{
	public var songData:SongData = new SongData("test", "unknown");
	
	public var songId:String = "";
	public var selectedChart: Int = 0;
	public var savePath: Null<String> = null;
	public var currentSongChart(get, never): SongChart;

	function get_currentSongChart(): SongChart {
		if (songData == null) return null;
		if (songData.chart.charts.length <= selectedChart) return null;
		return songData.chart.charts[selectedChart];
	}
	
	var haxeUIDialogOpen(get, never):Bool;
	function get_haxeUIDialogOpen(): Bool {
		return FocusManager.instance.focus != null;
	}

	var currentGamemode(get, never): Null<Gamemode>;
	function get_currentGamemode(): Null<Gamemode> {
		if (currentSongChart == null) return null;
		return Gamemode.gamemodes[currentSongChart.chartKey.gamemode];
	}
	var chart:FlxSpriteGroup;
	//var staffLines:FlxSprite;
	var staffLineGroup:FlxTypedSpriteGroup<Line>;
	public var strumLine:StrumLine;
	var curRenderedNotes:FlxTypedSpriteGroup<Note>;
	var curRenderedSus:FlxTypedSpriteGroup<SusNote>;
	var curRenderedSelects:FlxTypedSpriteGroup<SelectionSquare>;
	var snaptext:FlxText;
	var curSnap:Float = 0;
	var curKeyType:Int = Normal;
	var curSelectedNotes: Array<SongNoteData> = [];
	var curSelectedEvents: Array<SongEventData> = [];
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
	public var notePreviewDirty: Bool = false;
	public var quantizationDirty: Bool = false;
	public var chartDirty: Bool = false;
	public var saveDataDirty: Bool = false;
	public var commandHistoryDirty: Bool = false;
	var justAdded: Bool = false;

	var undoHistory:Array<commands.EditorCommand> = [];
	var redoHistory:Array<commands.EditorCommand> = [];

	public static final infosFont: String = "Roboto Bold";

	var metadataToolbox:toolboxes.MetadataToolbox; 
	var newChartToolbox:toolboxes.NewChartToolbox;
	var chartsToolbox:toolboxes.ChartsToolbox;

	override public function create()
	{
		super.create();
		strumLine = new StrumLine();
		curRenderedNotes = new FlxTypedSpriteGroup<Note>();
		curRenderedSus = new FlxTypedSpriteGroup<SusNote>();
		curRenderedSelects = new FlxTypedSpriteGroup<SelectionSquare>();
		// TODO: Camera scrolling
		staffLineGroup = new FlxTypedSpriteGroup<Line>();
		staffLineGroup.setPosition(0, 0);
		strumLine.setup(Gamemode.gamemodes["dance-single"]);
		strumLine.screenCenter(X);

		metadataToolbox = new toolboxes.MetadataToolbox(this);
		newChartToolbox = new toolboxes.NewChartToolbox(this);
		chartsToolbox = new toolboxes.ChartsToolbox(this);
		buildFileMenu();
		buildEditMenu();
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
		chart.add(curRenderedSelects);
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
		remove(menubar);
		// freaky...
		add(menubar);
	}



	private function loadFromFile(usePath:Bool=false):Void
	{
		var future = FNFAssets.askToBrowseForPath("vortexc", "Select Vortex Chart");
		future.onComplete(function(s:String)
		{
			try {
				final vortexc = VortexC.loadFromPath(s);
				loadFromVortexC(vortexc);
				if (usePath) savePath = s;
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
		if (songData == null) return;
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
	private function importSM(): Void {
		var future = FNFAssets.askToBrowseForPath("sm", "Import SM File");
		future.onComplete(function(s:String) {
			importSMFromPath(s);
		});
	}
	private function importSMFromPath(path:String): Void {
		// : )
		try {
			final data = File.getContent(path);
			songData = SM.fromSM(data);
			songId = songData.songName.toString();
			audioInstTrackData = File.getBytes(haxe.io.Path.join([haxe.io.Path.directory(path), songData.sm.songFile]));
			playerVocalTrackData = null;
			oppVocalTrackData = null;
			refreshFromFile();
		} catch (e) {
			trace(e);
		}
	}
	private function exportSM(): Void {
		if (songData == null) return;
		var future = FNFAssets.askToBrowseForPath("sm", "Export SM File", FileDialogType.SAVE);
		future.onComplete(function(s:String) {
			exportSMToPath(s); 
		});
	}
	private function exportSMToPath(path: String):Void {
		try {
			File.saveContent(path, songData.toSM());

		} catch (e) {
			trace(e);
		}
	}
	private function loadFromVortexC(vortexc: VortexC): Void {
		try {
			songData = vortexc.songData;
			songId = vortexc.songId;
			audioInstTrackData = vortexc.instrumental;
			playerVocalTrackData = vortexc.playerVocals;
			oppVocalTrackData = vortexc.opponentVocals;
			refreshFromFile();
		} catch (e) {
			trace(e);
		}
	}
	private function refreshFromFile(): Void {
		if (songData == null) return;
		Conductor.instance.mapTimeChanges(songData.timeChanges);
		selectedChart = 0;
		reloadInstrumental();
		metadataToolbox.refresh();
		chartsToolbox.refresh();
		noteDisplayDirty = true;
		chartDirty = true;
		saveDataDirty = false;
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
	private function handleFileKeybinds(): Void {
		if (haxeUIDialogOpen) return;
		if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.S) {
			if (FlxG.keys.pressed.SHIFT) {
				saveAs();
			} else {
				save();
			}
		}
		if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.O) {
			loadFromFile(true);
		}
	}
	private function handleEditKeybinds(): Void {
		if (haxeUIDialogOpen) return;
		if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.Z) {
			undoLastCommand();
		}
		if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.Y) {
			redoLastCommand();
		}
		if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.A) {
			if (FlxG.keys.pressed.SHIFT) {
				deselectNotes();
			} else {
				selectAll();
			}
		}
	}
	private function handleChartKeybinds(): Void {
		if (haxeUIDialogOpen) return;
		if (FlxG.keys.justPressed.F4) {
			changeDifficulty(false);	
		} else if (FlxG.keys.justPressed.F5){
			changeDifficulty(true);
		}
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
			loadFromFile(true);
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

		exportStepmaniaMenu.onClick = function(e: MouseEvent) {
			exportSM();
		};
		importStepmaniaMenu.onClick = function(e:MouseEvent) {
			importSM();
		};
	}
	private function buildEditMenu(): Void {
		undoMenu.onClick = function(e:MouseEvent) {
			undoLastCommand();	
		};
		redoMenu.onClick = function(e:MouseEvent) {
			redoLastCommand();
		};
		selectAllMenu.onClick = function(e:MouseEvent) {
			selectAll();
		};
		deselectAllMenu.onClick = function(e:MouseEvent) {
			deselectNotes();
		}
	}
	private function buildChartMenu(): Void {
		newChartMenu.onClick = function(e:MouseEvent) {
			newChartToolbox.showDialog(false);
		}
		prevChartMenu.onClick = function(e:MouseEvent) {
			changeDifficulty(false);
		};
		nextChartMenu.onClick = function(e:MouseEvent) {
			changeDifficulty(true);
		};
		toggleToolboxCharts.onChange = function (event:UIEvent) {
			if (event.target.value) {
				chartsToolbox.showDialog(false);
			} else {
				chartsToolbox.hideDialog(DialogButton.CANCEL);
			}
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
			FlxG.keys.justPressed.EIGHT,
			FlxG.keys.justPressed.NINE,
			FlxG.keys.justPressed.ZERO,
		];
		noteRelease = [
			FlxG.keys.justReleased.ONE,
			FlxG.keys.justReleased.TWO,
			FlxG.keys.justReleased.THREE,
			FlxG.keys.justReleased.FOUR,
			FlxG.keys.justReleased.FIVE,
			FlxG.keys.justReleased.SIX,
			FlxG.keys.justReleased.SEVEN,
			FlxG.keys.justReleased.EIGHT,
			FlxG.keys.justReleased.NINE,
			FlxG.keys.justReleased.ZERO,
		];
		noteHold = [
			FlxG.keys.pressed.ONE,
			FlxG.keys.pressed.TWO,
			FlxG.keys.pressed.THREE,
			FlxG.keys.pressed.FOUR,
			FlxG.keys.pressed.FIVE,
			FlxG.keys.pressed.SIX,
			FlxG.keys.pressed.SEVEN,
			FlxG.keys.pressed.EIGHT,
			FlxG.keys.pressed.NINE,
			FlxG.keys.pressed.ZERO,
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
				changeNoteKind(false);
			}
			else if (FlxG.keys.justPressed.E)
			{
				changeNoteKind(true);

			}
			if (FlxG.keys.justPressed.RIGHT)
			{
				changeSnap(true);
			}
			else if (FlxG.keys.justPressed.LEFT)
			{
				changeSnap(false);
			}
			/*
			if (FlxG.keys.justPressed.ESCAPE && curSelectedNote != null)
			{
				deselectNote();
			}
			*/
			if (FlxG.keys.justPressed.HOME)
			{
				strumLine.y = 0;
				moveStrumLine(0);
			}
			if (FlxG.keys.justPressed.GRAVEACCENT) {
				convertSelToRoll();
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
						if (note == null || note.noteData == null || !note.exists || !note.alive) continue;
						if (FlxG.mouse.overlaps(note))
						{
							toggleSelect(note.noteData);
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
						if (note == null || note.noteData == null || !note.exists || !note.alive) continue;
						if (FlxG.mouse.overlaps(note))
						{
							removeNote(note.noteData);
							break;
						}
					}
				}
			}


		}
		handleMusicPlayback(elapsed);
		handleFileKeybinds();
		handleEditKeybinds();
		handleChartKeybinds();

		if (currentGamemode != null && FocusManager.instance.focus == null) {
			for (i in 0...noteControls.length)
			{

				if (!noteControls[i] || currentGamemode.noteCount <= i)
					continue;
				if (FlxG.keys.pressed.CONTROL)
				{
					selectNote(i);
				}
				else
				{
					switch (getNoteAt(i)) {
						case null:
							addNote(i);
							justAdded = true;
						case note:
							curHoldSelect = note;
							justAdded = false;
					}
				}
			}
			for (i in 0...noteRelease.length)
			{
				if (!noteRelease[i] || currentGamemode.noteCount <= i)
					continue;
				if (curHoldSelect != null && curHoldSelect.data == i)
				{
					if (!justAdded && curHoldSelect.rowTime == getRow(strumLine.y)) {
						removeNote(curHoldSelect);
					}
					curHoldSelect = null;
				}

			}
		}
		handleChart();
		handleNotes();
		handleQuantization();
		camFollow.setPosition(FlxG.width / 2, strumLine.y + FlxG.height * 1 / 4);
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
		if (curHoldSelect != null)
		{
			curHoldSelect.length = strumRow - curHoldSelect.rowTime;
			curHoldSelect.length = Std.int(FlxMath.bound(curHoldSelect.length, 0));
		}
		updateNotes();
		Conductor.instance.update(Conductor.instance.getRowTimeInMs(strumRow));
		updateMeasure();
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

			final newMeasure:Bool = i % timeChange?.stepsPerMeasure() ?? 16 == 0;
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
	function convertToRoll(id:Int): Void
	{
		switch (getNoteAt(id)) {
			case null: return;
			case note:
				   if (note.length <= 0) return;
				   performCommand(new commands.ConvertNoteRollCommand([note], !note.isRoll));
		}
	}

	function convertSelToRoll(): Void {
		if (curSelectedNotes.length == 0) return;
		performCommand(new commands.ConvertNoteRollCommand(curSelectedNotes.clone(), !curSelectedNotes[0].isRoll));
	}

	private function addNote(id:Int):Void
	{
		if (songData == null) return;
		if (currentSongChart?.notes == null) return;
		switch (getNoteAt(id)) {
			case null:
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
				// jank
				curHoldSelect = goodNote;
				// : )
				performCommand(new commands.AddNotesCommand([goodNote]));
			case note:
				performCommand(new commands.RemoveNotesCommand([note]));
		}

	}

	private function removeNote(note:SongNoteData):Void {
		if (currentSongChart == null) return;
		performCommand(new commands.RemoveNotesCommand([note]));
	}



	private function changeNoteKind(increase:Bool): Void {
		if (increase) {
			curKeyType += 1;
		} else {
			curKeyType -= 1;
		}
		curKeyType = cast FlxMath.wrap(curKeyType, 0, Death);
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
			default:
				noteTypeText.text = 'Custom Note ${curKeyType - 4}';
		}
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
		if (increase) {
			selectedChart += 1;
		} else {
			selectedChart -= 1;
		}
		selectedChart = FlxMath.wrap(selectedChart, 0, songData.chart.charts.length - 1);

		loadChart(selectedChart);
	}

	public function loadChart(id: Int): Void {
		if (songData == null) return;
		selectedChart = id;
		metadataToolbox.refresh();
		chartsToolbox.refresh();
		chartDirty = true;
		noteDisplayDirty = true;
	}
	private function selectAll(): Void {
		performCommand(new commands.SelectAllItemsCommand());
	}

	private function deselectNotes():Void
	{
		// sectionInfo.visible = true;
		// noteInfo.visible = false;
		performCommand(new commands.DeselectAllItemsCommand());
	}

	private function deselectNote(id:Int): Void {
		switch (getNoteAt(id)) {
			case null: return;
			case note:
				   performCommand(new commands.DeselectItemsCommand([note], []));

		}
	}

	private function getNoteAt(id: Int): Null<SongNoteData> {
		if (songData == null) return null;
		if (currentSongChart?.notes == null) return null;
		final noteRow = getRow(strumLine.members[id].y);
		final noteData = id;
		for (note in currentSongChart.notes) {
			if (note.rowTime == noteRow && note.data == noteData) {
				return note;
			}
		}
		return null;
	}
	private function toggleSelectAt(id:Int): Void {
		switch (getNoteAt(id)) {
			case null: return;
			case note:
				   toggleSelect(note);
		}
	}
	private function toggleSelect(note: SongNoteData): Void {
		if (curSelectedNotes.fastContains(note)) {
			performCommand(new commands.DeselectItemsCommand([note], []));
		} else {
			performCommand(new commands.SelectItemsCommand([note], []));
		}
	}
	private function selectNote(id:Int):Void
	{
		if (songData == null) return;
		if (currentSongChart?.notes == null) return;

		switch (getNoteAt(id)) {
			case null: return;
			case note:
				   if (!curSelectedNotes.fastContains(note)) {
					   performCommand(new commands.SelectItemsCommand([note], []));
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

		if (currentSongChart != null) {
			strumLine.setup(currentGamemode);
			strumLine.screenCenter(X);
		}

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
				holdNoteSprite.sustainLength = holdNoteSprite.noteData.length;
				holdNoteSprite.updateHoldNotePosition();
			}
		}
		displayedHoldNoteData.insertionSort((a, b) -> FlxSort.byValues(FlxSort.ASCENDING, a.rowTime, b.rowTime));
		for (noteData in currentSongChart.notes) {
			if (noteData == null) continue;


			if (displayedNoteData.fastContains(noteData) && (noteData.length == 0 || displayedHoldNoteData.fastContains(noteData))) {
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

				holdNoteSprite.parentState = this;

				holdNoteSprite.noteData = noteSprite.noteData;

				holdNoteSprite.sustainLength = noteSprite.noteData.length;

				holdNoteSprite.updateHoldNotePosition();
				noteSprite.playNoteAnimation();
			}
		}

		handleNoteSelects();
	}

	private function handleNoteSelects(): Void {
		for (member in curRenderedSelects.members) {
			member.kill();
		}

		// ????????
		for (note in curSelectedNotes) {
			if (note == null) continue;
			var realNote: Note = null;
			for (renderNote in curRenderedNotes.members) {
				if (renderNote == null || !renderNote.exists || !renderNote.alive) continue;
				if (note == renderNote.noteData) {
					realNote = renderNote;
					break;
				}
			}
			if (realNote == null) continue;
			final renderedSel = curRenderedSelects.recycle(SelectionSquare);
			renderedSel.noteData = note;
			renderedSel.eventData = null;
			renderedSel.x = realNote.x;
			renderedSel.y = realNote.y;
			renderedSel.width = LINE_SPACING;
			renderedSel.height = (note.length <= 0) ? LINE_SPACING : ((note.length / Constants.ROWS_PER_STEP + 1) * LINE_SPACING);
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

	public function sortChartData(): Void {
		if (currentSongChart == null) return;
		currentSongChart.notes.insertionSort(SortUtil.noteDataByTime.bind(FlxSort.ASCENDING, _, _));
		songData.chart.events.insertionSort(SortUtil.eventDataByTime.bind(FlxSort.ASCENDING, _, _));
	}

	public function performCommand(command:commands.EditorCommand, purgeRedoStack:Bool = true):Void
	{
		command.execute(this);
		if (command.shouldAddToHistory(this)) {
			undoHistory.push(command);
			commandHistoryDirty = true;
		}
		if (purgeRedoStack) redoHistory = [];
	}

	function undoCommand(command:commands.EditorCommand):Void {
		command.undo(this);
		redoHistory.push(command);
		commandHistoryDirty = true;
	}

	public function undoLastCommand():Void {
		switch (undoHistory.pop()) {
			case null:
				trace('No actions to undo.');
				return;
			case command:
				undoCommand(command);
		}
	}
	public function redoLastCommand():Void {
		switch (redoHistory.pop()) {
			case null:
				trace('No actions to redo.');
				return;
			case command:
				performCommand(command, false);
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
