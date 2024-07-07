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



  static function load(): Array<Gamemode> {
    final parser = new json2object.JsonParser<Array<Gamemode>>();
    final arr = parser.fromJson(FNFAssets.getText("assets/data/gamemodes.json"));
    return arr;
  }

  public static var gamemodeArr(get, null): Array<Gamemode> = null;
  public static var gamemodes(get, null): Map<String, Gamemode> = null;

  static function get_gamemodeArr(): Array<Gamemode> {
    if (gamemodeArr == null)
      gamemodeArr = load();
    return gamemodeArr;
  }
  static function get_gamemodes(): Map<String, Gamemode> {
    if (gamemodes == null) {
      final arr = get_gamemodeArr();
      final map = new Map<String, Gamemode>();
      for (item in arr) {
        map.set(item.id, item);
      }
      gamemodes = map;
    }
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
