//=============================================================================
//  MuseScore
//  Music Composition & Notation
//
//  Copyright (C) 2015 Nicolas Froment
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License version 2
//  as published by the Free Software Foundation and appearing in
//  the file LICENCE.GPL
//=============================================================================

import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Layouts 1.1
import MuseScore 1.0

MuseScore {
      version:  "1.0"
      description: "Tonic Solfa"
      menuPath: "Plugins.Notes.Tonic Solfa"

      //                          -7   -6   -5   -4   -3   -2   -1    0    1    2    3    4    5    6    7
      property variant scales :  ['C', 'G', 'D', 'A', 'E', 'B', 'F', 'C', 'G', 'D', 'A', 'E', 'B', 'F', 'C'];
      property string tpcNames: "FCGDAEB";
      property string names: "CDEFGAB";

      property variant degrees: ["d", "r", "m", "f", "s", "l", "t"];

      function tonicText(note, curKey) {
          var tpcNames = "FCGDAEB";
          var name = tpcNames[(note.tpc + 1) % 7];
          var scale = scales[curKey+7];
          var octave = Math.floor(note.pitch / 12) - 1;
          var oString = ""
          if (octave == 4)
                oString = "'"
          else if (octave == 2)
                oString = "╷"
          return degrees[(names.indexOf(name) - names.indexOf(scale) +28)%7] + oString;

      }

      function nameChord (notes, text, curKey, staffIdx, voice) {
          for (var i = 0; i < notes.length; i++) {
              var sep = "\n"; // change to "\n" if you want them vertically
              text.text = tonicText(notes[i], curKey)
          }
          if (staffIdx % 2 == 0) {
              switch (voice) {
                 case 0: text.pos.y =  -4; break;
                 case 1: text.pos.y = -1.5; break;
                 //case 2: text.pos.y = -1; break;
                 //case 3: text.pos.y = 12; break;
              }
          }
          else {
              switch (voice) {
                 case 0: text.pos.y =  12; break;
                 case 1: text.pos.y =  14; break;
                 //case 2: text.pos.y = -1; break;
                 //case 3: text.pos.y = 12; break;
              }
          }

      }

      onRun: {
          if (typeof curScore === 'undefined')
             Qt.quit();

          var cursor = curScore.newCursor();
          var startStaff;
          var endStaff;
          var endTick;
          var fullScore = false;
          cursor.rewind(1);
          if (!cursor.segment) { // no selection
             fullScore = true;
             startStaff = 0; // start with 1st staff
             endStaff  = curScore.nstaves - 1; // and end with last
          } else {
             startStaff = cursor.staffIdx;
             cursor.rewind(2);
             if (cursor.tick == 0) {
                // this happens when the selection includes
                // the last measure of the score.
                // rewind(2) goes behind the last segment (where
                // there's none) and sets tick=0
                endTick = curScore.lastSegment.tick + 1;
             } else {
                endTick = cursor.tick;
             }
             endStaff = cursor.staffIdx;
          }

          for (var staff = startStaff; staff <= endStaff; staff++) {
             for (var voice = 0; voice < 4; voice++) {
                cursor.rewind(1); // beginning of selection
                cursor.voice    = voice;
                cursor.staffIdx = staff;

                if (fullScore)  // no selection
                   cursor.rewind(0); // beginning of score

                while (cursor.segment && (fullScore || cursor.tick < endTick)) {
                   if (cursor.element && cursor.element.type == Element.CHORD) {
                      var text = newElement(Element.STAFF_TEXT);

                      var graceChords = cursor.element.graceNotes;
                      for (var i = 0; i < graceChords.length; i++) {
                         // iterate through all grace chords
                         var notes = graceChords[i].notes;
                         nameChord(notes, text, cursor.keySignature, staff, voice);
                         // there seems to be no way of knowing the exact horizontal pos.
                         // of a grace note, so we have to guess:
                         text.pos.x = -2.5 * (graceChords.length - i);

                         cursor.add(text);
                         // new text for next element
                         text  = newElement(Element.STAFF_TEXT);
                      }

                      var notes = cursor.element.notes;
                      nameChord(notes, text, cursor.keySignature, staff, voice);

                      if ((voice == 0) && (notes[0].pitch > 83))
                         text.pos.x = 1;
                      cursor.add(text);
                   } // end if CHORD
                   cursor.next();
                } // end while segment
             } // end for voice
          } // end for staff
          Qt.quit();
      } // end onRun
}
