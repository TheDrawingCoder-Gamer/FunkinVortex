package vortex.data.song;

import vortex.data.song.SongData.SongTimeChange;
import vortex.data.song.SongData.SongStop;
import vortex.data.song.SongData.SongNoteData;
import vortex.data.song.SongData.SongChart;
import vortex.data.song.SongData.ChartKey;
import flixel.util.FlxSort;
// Static extension to convert SongData to and from SM

class SM {
  static function smDataToSM(sm:SongData.SongSMData): String {
    final buf = new StringBuf();

    if (sm.subtitle != null) {
      buf.add('#SUBTITLE:${sm.subtitle};\n');
    }
    if (sm.titleTranslit != null) {
      buf.add('#TITLETRANSLIT:${sm.titleTranslit};\n');
    }
    if (sm.subtitleTranslit != null) {
      buf.add('#SUBTITLETRANSLIT:${sm.subtitleTranslit};\n');
    }
    if (sm.genre != null) {
      buf.add('#GENRE:${sm.genre};\n');
    }
    if (sm.banner != null) {
      buf.add('#BANNER:${sm.banner};\n');
    }
    if (sm.lyricsPath != null) {
      buf.add('#LYRICSPATH:${sm.lyricsPath};\n');
    }
    if (sm.cdTitle != null) {
      buf.add('#CDTITLE:${sm.cdTitle};\n');
    }
    buf.add('#SELECTABLE:${sm.selectable ? "YES" : "NO"};\n');
    if (sm.bgChanges != null) {
      buf.add('#BGCHANGES:${sm.bgChanges};\n');
    }
    if (sm.fgChanges != null) {
      buf.add('#FGCHANGES:${sm.fgChanges};\n');
    }
    if (sm.background != null) {
      buf.add('#BACKGROUND:${sm.background};\n');
    }
    if (sm.displayBpm != null) {
      buf.add('#DISPLAYBPM:${sm.background};\n');
    }

    for (key => value in sm.extraFields) {
      buf.add('#${key}:${value};\n');
    }

    return buf.toString();

  }
  public static function toSM(data:SongData): String {
    final buf = new StringBuf();
    buf.add('#TITLE:${data.songName};\n');
    buf.add('#ARTIST:${data.artist};\n');
    if (data.charter != null)
      buf.add('#CREDIT:${data.charter};\n');
    final bpmChanges: Array<String> = 
      [for (change in data.timeChanges) {a: change.rowTime / Constants.ROWS_PER_BEAT, b: change.bpm}].map(it -> '${it.a}=${it.b}');
    final daStops: Array<String> =
      [for (stop in data.stops) '${stop.rowTime / Constants.ROWS_PER_BEAT}=${stop.length}'];

    buf.add('#BPMS:${bpmChanges.join(',')};\n');
    buf.add('#STOPS:${daStops.join(',')};\n');
    buf.add('#SAMPLESTART:${data.playData.previewStart / 1000};\n');
    buf.add('#SAMPLELENGTH:${data.playData.previewLength / 1000};\n');
    buf.add('#MUSIC:${data.sm.songFile ?? (data.songName + ".ogg")};\n');
    buf.add(smDataToSM(data.sm));
    for (c in data.chart.charts) {
      buf.add('// -- ${c.chartKey.gamemode} - ${c.chartKey.difficulty}\n');
      buf.add('#NOTES:\n');
      buf.add('    ${c.chartKey.gamemode}:\n');
      final goodDiff = c.chartKey.difficulty == 'normal' ? 'medium' : c.chartKey.difficulty;
      final weirdDiff = switch (goodDiff) {
        case "medium" | "hard" | "easy" | "beginning" | "challenge" | "edit": false;
        default: true;
      }
      buf.add('    ${weirdDiff ? goodDiff : ""}:\n');
      buf.add('    ${weirdDiff ? "Edit" : goodDiff.capitalizeFirst()}:\n');
      buf.add('    ${c.stepmaniaRating}:\n');
      buf.add('    0,0,0,0,0:\n');
      c.notes.insertionSort((x, y) -> FlxSort.byValues(FlxSort.ASCENDING, x.rowTime, y.rowTime));
      final lastNote = c.notes[c.notes.length - 1];
      // TODO: detect sustain correctly
      final sectionCount = Math.ceil(lastNote.rowTime + lastNote.length / Constants.ROWS_PER_MEASURE);
      final gamemodeNoteCount = Gamemode.gamemodes[c.chartKey.gamemode]?.noteCount ?? 4;
      var curNote: Int = 0;
      var strumEnds: Array<Int> = [for (i in 0...gamemodeNoteCount) -1];
      for (sect in 0...sectionCount) {
        if (sect != 0) buf.add(',\n');
        var quant: Int = 0; // 4
        final minNote: Int = curNote;
        var maxNote: Int = curNote;
        var stinkyNote: Int = minNote;
        while (true) {
          if (stinkyNote >= c.notes.length) {
            maxNote = c.notes.length;
            break;
          }
          // ???
          final section = Math.floor(c.notes[stinkyNote].rowTime / Constants.ROWS_PER_MEASURE);
          if (section > sect) {
            maxNote = stinkyNote;
            break;
          } else {
            for (q in 0...Constants.QUANT_ARRAY.length) {
              final daQuant = Constants.QUANT_ARRAY[q];
              if (c.notes[stinkyNote].rowTime % Math.round(Constants.ROWS_PER_MEASURE / daQuant) == 0) {
                if (q > quant)
                  quant = q;
                break;
              }
            }
            final goodTime = c.notes[stinkyNote].rowTime + c.notes[stinkyNote].length;
            if (goodTime < (sect + 1) * Constants.ROWS_PER_MEASURE) {
              for (q in 0...Constants.QUANT_ARRAY.length) {
                final daQuant = Constants.QUANT_ARRAY[q];
                if (goodTime % Math.round(Constants.ROWS_PER_MEASURE / daQuant) == 0) {
                  if (q > quant) 
                    quant = q;
                  break;
                }
              }
            }
          }
          stinkyNote += 1;
        }
        curNote = maxNote;
        final sectOffset = sect * Constants.ROWS_PER_MEASURE;
        for (note in strumEnds) {
          if (note < sectOffset || note >= (sect + 1) * Constants.ROWS_PER_MEASURE) continue;
          for (q in 0...Constants.QUANT_ARRAY.length) {
            final daQuant = Constants.QUANT_ARRAY[q];
            if (note % Math.round(Constants.ROWS_PER_MEASURE / daQuant) == 0) {
              if (q > quant)
                quant = q;
              break;
            }
          }
        }
        final goodQuant = Constants.QUANT_ARRAY[quant];
        final finalNotes: Array<Array<String>> = [for (i in 0...goodQuant) [for (j in 0...gamemodeNoteCount) "0"]];
        for (i in minNote...maxNote) {
          // freaky....
          final daNote = c.notes[i];
          final noteIdx = Math.round(goodQuant * (daNote.rowTime - sectOffset) / Constants.ROWS_PER_MEASURE);
          finalNotes[noteIdx][daNote.data] = 
            if (daNote.length > 0)
                if (daNote.isRoll) 
                  "4"
                else
                  "2"
            else
              switch (daNote.kind) {
                // ?
                case "mine" | "nuke": 
                  "M";
                case "lift":
                  "L";
                case "fake":
                  "F";
                case "keysound":
                  "K";
                default:
                  "1";
              }
          ;
          if (daNote.length > 0) {
            // jank
            // TODO: if u place a note between this prob breaks : )
            
            final endIdx = Math.round(goodQuant * (daNote.rowTime + daNote.length - sectOffset) / Constants.ROWS_PER_MEASURE);
            if (endIdx > goodQuant) {
              strumEnds[daNote.data] = daNote.rowTime + daNote.length;
            } else {
              finalNotes[endIdx][daNote.data] = "3";
            }
          }
        }
        for (i => possibleStrum in strumEnds) {
          final goodStrum = possibleStrum - sectOffset;
          if (goodStrum < 0) continue;
          if (goodStrum > Constants.ROWS_PER_MEASURE) continue;
          final strumEndIdx = Math.round((goodQuant * goodStrum) / Constants.ROWS_PER_MEASURE);
          finalNotes[strumEndIdx][i] = "3";


        }
        buf.add(finalNotes.map(it -> it.join("")).join("\n"));
        buf.add("\n");

      }
      buf.add(";\n");

    }

    return buf.toString();
  }
  public static function fromSM(sm:String): SongData {
    final res = new SongData("", "", "");

    final daRegex = ~/#([\s\S]+?):([\s\S]*?);/;
    var curIndex:Int = 0;
    while (curIndex < sm.length) {
      if (daRegex.matchSub(sm, curIndex)) {
        final key = daRegex.matched(1);
        final value = daRegex.matched(2);
        switch (key) {
          case "TITLE":
            res.songName = value;
          case "SUBTITLE":
            res.sm.subtitle = value;
          case "ARTIST":
            res.artist = value;
          case "TITLETRANSLIT":
            res.sm.titleTranslit = value;
          case "SUBTITLETRANSLIT":
            res.sm.subtitleTranslit = value;
          case "GENRE":
            res.sm.genre = value;
          case "CREDIT":
            res.charter = value;
          case "BANNER":
            res.sm.banner = value;
          case "BACKGROUND":
            res.sm.background = value;
          case "LYRICSPATH":
            res.sm.lyricsPath = value;
          case "CDTITLE":
            res.sm.cdTitle = value;
          case "MUSIC":
            res.sm.songFile = value;
          case "OFFSET":
            res.offsets.instrumental = Std.parseFloat(value) * 1000;
          case "BPMS":
            res.timeChanges = [];
            for (item in value.split(",")) {
              final lrs = item.split("=");
              final daRow = Math.round(Std.parseFloat(lrs[0]) * Constants.ROWS_PER_BEAT);
              final daBpm = Std.parseFloat(lrs[1]);
              // : )
              res.timeChanges.push(new SongTimeChange(daRow, daBpm));
            }
            SongDataUtils.sortTimeChanges(res.timeChanges);
          case "STOPS":
            res.stops = [];
            for (item in value.split(",")) {
              final lrs = item.split("=");
              final daRow = Math.round(Std.parseFloat(lrs[0]) * Constants.ROWS_PER_BEAT);
              final daLength = Std.parseFloat(lrs[1]);
              res.stops.push(new SongStop(daRow, daLength));
            }
            res.stops.sort((a, b) -> FlxSort.byValues(FlxSort.ASCENDING, a.rowTime, b.rowTime));
          case "SAMPLESTART":
            res.playData.previewStart = Math.round(Std.parseFloat(value) * 1000);
          case "SAMPLELENGTH":
            res.playData.previewLength = Math.round(Std.parseFloat(value) * 1000);
          case "DISPLAYBPM":
            res.sm.displayBpm = value;
          case "SELECTABLE":
            res.sm.selectable = value.trim() != "NO";
          case "BGCHANGES":
            res.sm.bgChanges = value;
          case "FGCHANGES":
            res.sm.fgChanges = value;
          case "NOTES":
              // :troll:
              final daThings = value.split(":");
              final gamemode = daThings[0].trim();
              final noteCount = Gamemode.gamemodes[gamemode]?.noteCount ?? 4;
              final description = daThings[1].trim();
              final difficulty = daThings[2].trim();
              var goodDifficulty = 
                if (difficulty == 'Edit' && description != "")
                  description
                else
                  difficulty.toLowerCase()
              ;
              if (goodDifficulty == "medium")
                goodDifficulty = "normal";
              final meter = Std.parseFloat(daThings[3].trim());
              // skip groove radar
              final noteData = daThings[5].trim();
              final sections = noteData.split(",");
              final chart = new SongChart(new ChartKey(goodDifficulty, gamemode), 1.0, [], 1, meter);
              var allRows:Array<String> = [];
              for (section in sections) {
                final rows = section.trim().split("\n");
                final steps = Std.int(Constants.ROWS_PER_MEASURE / rows.length);
                for (noteRow in rows) {
                  allRows.push(noteRow.trim());
                  if (steps - 1 > 0) {
                    for (i in 0...steps - 1) {
                      // : )
                      allRows.push("".rpad("0", noteCount));
                    }
                  }
                }
              }
              for (rowTime => row in allRows) {
                for (i in 0...noteCount) {
                  switch (row.charCodeAt(i)) {
                    case "0".code | "3".code: 
                      // freakly...
                    case "1".code:
                      chart.notes.push(new SongNoteData(rowTime, i, 0));
                    case "2".code | "4".code:
                      // freaky...
                      var susEnd: Int = rowTime;
                      while (susEnd < allRows.length) {
                          if (allRows[susEnd].charCodeAt(i) == "3".code) {
                            break;
                          }
                          susEnd++;
                      }
                      if (susEnd < allRows.length) {
                        chart.notes.push(new SongNoteData(rowTime, i, susEnd - rowTime, '', row.charCodeAt(i) == "4".code));
                      }
                    case "M".code:
                      chart.notes.push(new SongNoteData(rowTime, i, 0, 'mine'));
                    case "L".code:
                      chart.notes.push(new SongNoteData(rowTime, i, 0, 'lift'));
                    case "F".code:
                      chart.notes.push(new SongNoteData(rowTime, i, 0, 'fake'));
                    case "K".code:
                      chart.notes.push(new SongNoteData(rowTime, i, 0, 'keysound'));
                    default:
                      // freaky deaky...
                  }
                }
              }
              res.chart.charts.push(chart);
        }
        final matchedPos = daRegex.matchedPos();
        curIndex = matchedPos.pos + matchedPos.len - 1;
      } else {
        break;
      }
    }
    return res;
  }
}
