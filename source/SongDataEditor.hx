package;

import haxe.ui.containers.TabView;
import haxe.ui.events.MouseEvent;
import haxe.ui.events.UIEvent;
import vortex.data.song.SongData.SongChartData;
import vortex.data.song.SongData.SongMetadata;
import vortex.data.song.SongData.SongNoteData;

@:build(haxe.ui.macros.ComponentMacros.build("assets/data/tabmenu.xml"))
class SongDataEditor extends TabView
{
	var playstate:PlayState;

	public function new(playstate:PlayState)
	{
		super();
		this.playstate = playstate;
	}

	private var metadata(get, set):SongMetadata;
	private var _song(get, set):SongChartData;

	private var _note(get, set):Null<SongNoteData>;

	private function get_metadata():SongMetadata {
		return cast PlayState.songMetadata;
	}

	private function set_metadata(value: SongMetadata):SongMetadata {
		PlayState.songMetadata = value;
		refreshUI(PlayState.songMetadata, PlayState.songChartData);
		return value;
	}
	private function get__note():Null<SongNoteData>
	{
		return cast playstate.curSelectedNote;
	}

	private function set__note(value:Null<SongNoteData>):Null<SongNoteData>
	{
		playstate.curSelectedNote = value;
		if (value != null) {
			refreshNoteUI(value);
		}
		return playstate.curSelectedNote;
	}

	private function get__song(): SongChartData
	{
		return PlayState.songChartData;
	}

	private function set__song(goodSong:SongChartData):SongChartData
	{
		PlayState.songChartData = goodSong;
		refreshUI(PlayState.songMetadata, PlayState.songChartData);
		return goodSong;
	}

	public function refreshUI(metadata: SongMetadata, goodSong:SongChartData)
	{
		bfText.text = metadata.playData.characters.player;
		enemyText.text = metadata.playData.characters.opponent;
		gfText.text = metadata.playData.characters.girlfriend;
		stageText.text = metadata.playData.stage;
		uiText.text = metadata.playData.noteStyle;
		songTitle.text = metadata.songName;
		if (metadata.timeChanges[0] != null) {
			songbpm.pos = metadata.timeChanges[0].bpm;
		}
	}

	public function refreshNoteUI(goodNote:SongNoteData)
	{
		// : )
	}


	@:bind(songbpm, UIEvent.CHANGE)
	function change_songbpm(_)
	{
		if (metadata.timeChanges[0] != null) {
			metadata.timeChanges[0].bpm = songbpm.pos;
		}
		Conductor.instance.mapTimeChanges(metadata.timeChanges);
	}
	@:bind(songTitle, UIEvent.CHANGE)
	function change_songTitle(_)
	{
		metadata.songName = songTitle.text; 
	}
	@:bind(bfText, UIEvent.CHANGE)
	function change_bfText(_)
	{
		metadata.playData.characters.player = bfText.text;
	}
	@:bind(enemyText, UIEvent.CHANGE)
	function change_enemyText(_)
	{
		metadata.playData.characters.opponent = enemyText.text;
	}
	@:bind(gfText, UIEvent.CHANGE)
	function change_gfText(_)
	{
		metadata.playData.characters.girlfriend = gfText.text;
	}
	@:bind(stageText, UIEvent.CHANGE)
	function change_stageText(_)
	{
		metadata.playData.stage = stageText.text;
	}
	@:bind(uiText, UIEvent.CHANGE)
	function change_uiText(_)
	{
		metadata.playData.noteStyle = uiText.text;
	}

}
