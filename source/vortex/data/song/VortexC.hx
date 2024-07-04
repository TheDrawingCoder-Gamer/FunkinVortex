package vortex.data.song;

import haxe.io.Bytes;
import vortex.util.FileUtil;
import vortex.data.song.vslice.importer.ChartManifestData;
import vortex.data.song.vslice.FNFC.FNFCSong;

// A vortex chart.
class VortexC {
  public var songId: String;
  public var path: Null<String> = null;
  public var songData: SongData;
  public var instrumental: Bytes;
  public var playerVocals: Null<Bytes>;
  public var opponentVocals: Null<Bytes>;

  public function new(songId: String, songData: SongData, instrumental: Bytes, ?playerVocals: Bytes, ?opponentVocals: Bytes, ?path: String) {
    this.songId = songId;
    this.path = path;
    this.songData = songData;
    this.instrumental = instrumental;
    this.playerVocals = playerVocals;
    this.opponentVocals = opponentVocals;
  }
  public static function load(bytes: Bytes): VortexC {
    final fileEntries = FileUtil.readZIPFromBytes(bytes);
    final mappedFileEntries = FileUtil.mapZIPEntriesByName(fileEntries);

    final manifestBytes: Null<Bytes> = mappedFileEntries.get('manifest.json')?.data;
    if (manifestBytes == null) throw 'Could not locate manifest.';
    final manifestString = manifestBytes.toString();
    final manifest = ChartManifestData.deserialize(manifestString);
    if (manifest == null) throw 'Could not read manifest.';

    final dataPath = manifest.getCombinedDataFileName();

    final dataBytes = mappedFileEntries.get(dataPath)?.data;
    if (dataBytes == null) throw 'Could not locate data';
    final dataString = dataBytes.toString();
    final data = SongData.deserialize(dataString);

    final instId = data?.playData?.characters?.instrumental ?? '';
    final playerCharId = data?.playData?.characters?.player ?? Constants.DEFAULT_CHARACTER;
    final opponentCharId: Null<String> = data?.playData?.characters?.opponent ?? Constants.DEFAULT_OPPONENT;

    final instFileName = manifest.getInstFileName(instId);
    final instrumental = mappedFileEntries.get(instFileName)?.data;
    if (instrumental == null) throw 'Could not locate instrumental';

    final playerVocalsFileName = manifest.getVocalsFileName(playerCharId);
    final playerVocals: Null<Bytes> = mappedFileEntries.get(playerVocalsFileName)?.data;

    var opponentVocals: Null<Bytes> = null;

    if (opponentCharId != null) {
      final opponentVocalsFileName = manifest.getVocalsFileName(opponentCharId);
      opponentVocals = mappedFileEntries.get(opponentVocalsFileName)?.data;
    }

    return new VortexC(manifest.songId, data, instrumental, playerVocals, opponentVocals);  
  }

  public static function loadFromPath(path: String): Null<VortexC> {
    final bytes = FileUtil.readBytesFromPath(path);
    if (bytes == null) return null;

    final result = load(bytes);
    if (result != null) {
      result.path = path;
    }
    return result;
  }
  public static function fromFNFCSong(song: FNFCSong): VortexC {
    final songData = SongData.fromVSlice(song.songMetadata, song.songChartData); 
    return new VortexC(song.songId, songData, song.instrumental, song.playerVocals, song.opponentVocals);
  }

  public function save(path: String, ?onSaveCb:String->Void, ?onCancelCb:Void->Void): Void {
    var zipEntries:Array<haxe.zip.Entry> = [];

    zipEntries.push(FileUtil.makeZIPEntry('${songId}.json', songData.serialize()));
    final manifest = new ChartManifestData(songId);
    final instId = songData?.playData?.characters?.instrumental ?? '';
    zipEntries.push(FileUtil.makeZIPEntryFromBytes(manifest.getInstFileName(instId), instrumental));
    if (playerVocals != null) {
      final playerCharId = songData?.playData?.characters?.player ?? Constants.DEFAULT_CHARACTER;
      zipEntries.push(FileUtil.makeZIPEntryFromBytes(manifest.getVocalsFileName(playerCharId), playerVocals));
    }
    if (opponentVocals != null) {
      final opponentCharId = songData?.playData?.characters?.opponent ?? Constants.DEFAULT_OPPONENT;
      zipEntries.push(FileUtil.makeZIPEntryFromBytes(manifest.getVocalsFileName(opponentCharId), opponentVocals));
    }
  }
}
