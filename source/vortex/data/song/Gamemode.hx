package vortex.data.song;

class Gamemode {
  public var id: String;
  public var displayName: String;
  public var noteCount: Int;
  @:default(1)
  @:optional
  public var numPlayers: Int;
  public var notes: Array<GamemodeNoteInfo>;
  public function new() {}


  static function load(): Map<String, Gamemode> {
    final parser = new json2object.JsonParser<Array<Gamemode>>();
    final arr = parser.fromJson(FNFAssets.getText("assets/data/gamemodes.json"));
    final damap = new Map<String, Gamemode>();
    for (item  in arr) {
      damap.set(item.id, item);
    }
    return damap;
  }

  public static var gamemodes(get, null): Map<String, Gamemode> = null;

  static function get_gamemodes(): Map<String, Gamemode> {
    if (gamemodes == null)
      gamemodes = load();
    return gamemodes;
  }
}

class GamemodeNoteInfo {
  @:default(vortex.data.song.NoteKind.NORMAL)
  @:optional
  public var noteKind: NoteKind;
  // The amount of times rotated 90 degrees
  @default(0)
  @:optional
  public var rot90: Int;
  public function new(noteKind: NoteKind, rotateBy: Int) {
    this.noteKind = noteKind;
    this.rot90 = rotateBy;
  }
}
