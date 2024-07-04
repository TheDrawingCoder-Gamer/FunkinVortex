package vortex.data.song.vslice;

import haxe.io.Bytes;
import vortex.util.FileUtil;
import vortex.data.song.vslice.importer.ChartManifestData;
import vortex.data.song.vslice.SongData.SongMetadata;
import vortex.data.song.vslice.SongData.SongChartData;

// A single song 
class FNFCSong {
  public final songId: String;
  public final songMetadata: SongMetadata;
  public final songChartData: SongChartData;
  public final instrumental: Bytes;
  public final playerVocals: Null<Bytes>;
  public final opponentVocals: Null<Bytes>;

  public function new(songId: String, metadata: SongMetadata, chartData: SongChartData, instrumental: Bytes, ?playerVocals: Bytes, ?opponentVocals: Bytes) {
    this.songId = songId;
    this.songMetadata = metadata;
    this.songChartData = chartData;
    this.instrumental = instrumental;
    this.playerVocals = playerVocals;
    this.opponentVocals = opponentVocals;
  }
}
class FNFC {
  public var path: Null<String> = null;
  public var songId: String;
  public var songMetadatas: Map<String, SongData.SongMetadata> = [];
  public var songChartDatas: Map<String, SongData.SongChartData> = [];
  public var instrumentals: Map<String, Bytes> = [];
  public var playerVocals: Map<String, Bytes> = [];
  public var opponentVocals: Map<String, Bytes> = [];

  public function new() {}
  public function getVariation(variation: String): Null<FNFCSong> {
    final metadata = songMetadatas.get(variation);
    if (metadata == null) return null;
    final chartData = songChartDatas.get(variation);
    if (chartData == null) return null;
    final instrumental = instrumentals.get(variation);
    if (instrumental == null) return null;
    final playerVocal = playerVocals.get(variation);
    final opponentVocal = opponentVocals.get(variation);
    return new FNFCSong(songId, metadata, chartData, instrumental, playerVocal, opponentVocal);
  }
  public static function loadFromPath(path:String): Null<FNFC> {
    final bytes = FileUtil.readBytesFromPath(path);
    if (bytes == null) return null;

    final result = load(bytes);
    if (result != null) {
      result.path = path;
    }
    return result;
  }
  public static function load(bytes: Bytes): FNFC {
    final fnfc = new FNFC();
    final fileEntries = FileUtil.readZIPFromBytes(bytes);
    final mappedFileEntries = FileUtil.mapZIPEntriesByName(fileEntries);

    final manifestBytes:Null<Bytes> = mappedFileEntries.get('manifest.json')?.data;
    if (manifestBytes == null) throw 'Could not locate manifest.';
    final manifestString = manifestBytes.toString();
    final manifest:Null<ChartManifestData> = ChartManifestData.deserialize(manifestString);
    if (manifest == null) throw 'Could not read manifest.';

    fnfc.songId = manifest.songId;

    final baseMetadataPath = manifest.getMetadataFileName();
    final baseChartDataPath = manifest.getChartDataFileName();

    final baseMetadataBytes = mappedFileEntries.get(baseMetadataPath)?.data;
    if (baseMetadataBytes == null) throw 'Could not locate metadata (default).';
    final baseMetadataString = baseMetadataBytes.toString();
    // TODO: migration

    final baseMetadata = SongData.SongMetadata.deserialize(baseMetadataString);
    if (baseMetadata == null) throw 'Could not read metadata (default)';
    fnfc.songMetadatas.set(Constants.DEFAULT_VARIATION, baseMetadata);

    final baseChartDataBytes = mappedFileEntries.get(baseChartDataPath)?.data;
    if (baseChartDataBytes == null) throw 'Could not locate chart data (default).';
    final baseChartDataString = baseChartDataBytes.toString();

    final baseChartData = SongData.SongChartData.deserialize(baseChartDataString);
    if (baseChartData == null) throw 'Could not read chart data (default).';
    fnfc.songChartDatas.set(Constants.DEFAULT_VARIATION, baseChartData);

    final variationList = baseMetadata.playData.songVariations;

    for (variation in variationList)
    {
      var variMetadataPath:String = manifest.getMetadataFileName(variation);
      var variChartDataPath:String = manifest.getChartDataFileName(variation);

      var variMetadataBytes:Null<Bytes> = mappedFileEntries.get(variMetadataPath)?.data;
      if (variMetadataBytes == null) throw 'Could not locate metadata ($variation).';
      var variMetadataString:String = variMetadataBytes.toString();

      var variMetadata:Null<SongMetadata> = SongData.SongMetadata.deserialize(variMetadataString);
      if (variMetadata == null) throw 'Could not read metadata ($variation).';
      fnfc.songMetadatas.set(variation, variMetadata);

      var variChartDataBytes:Null<Bytes> = mappedFileEntries.get(variChartDataPath)?.data;
      if (variChartDataBytes == null) throw 'Could not locate chart data ($variation).';
      var variChartDataString:String = variChartDataBytes.toString();

      var variChartData:Null<SongChartData> = SongData.SongChartData.deserialize(variChartDataString);
      if (variChartData == null) throw 'Could not read chart data ($variation).';
      fnfc.songChartDatas.set(variation, variChartData);
    }

    // Load instrumentals
    for (variation in [Constants.DEFAULT_VARIATION].concat(variationList))
    {
      var variMetadata:Null<SongMetadata> = fnfc.songMetadatas.get(variation);
      if (variMetadata == null) continue;

      var instId:String = variMetadata?.playData?.characters?.instrumental ?? '';
      var playerCharId:String = variMetadata?.playData?.characters?.player ?? Constants.DEFAULT_CHARACTER;
      var opponentCharId:Null<String> = variMetadata?.playData?.characters?.opponent;

      var instFileName:String = manifest.getInstFileName(instId);
      var instFileBytes:Null<Bytes> = mappedFileEntries.get(instFileName)?.data;
      if (instFileBytes != null)
      {
        fnfc.instrumentals[variation] = instFileBytes;
      }
      else
      {
        throw 'Could not find instrumental ($instFileName).';
      }

      var playerVocalsFileName:String = manifest.getVocalsFileName(playerCharId);
      var playerVocalsFileBytes:Null<Bytes> = mappedFileEntries.get(playerVocalsFileName)?.data;
      if (playerVocalsFileBytes != null)
      {
        fnfc.playerVocals[variation] = playerVocalsFileBytes;
      }
      else
      {
        //warnings.push('Could not find vocals ($playerVocalsFileName).');
        // throw 'Could not find vocals ($playerVocalsFileName).';
      }

      if (opponentCharId != null)
      {
        var opponentVocalsFileName:String = manifest.getVocalsFileName(opponentCharId);
        var opponentVocalsFileBytes:Null<Bytes> = mappedFileEntries.get(opponentVocalsFileName)?.data;
        if (opponentVocalsFileBytes != null)
        {
          fnfc.opponentVocals[variation] = opponentVocalsFileBytes;
        }
        else
        {
          // throw 'Could not find vocals ($opponentVocalsFileName).';
        }
      }
    }
    return fnfc;
  }
}
