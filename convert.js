
// run me like this:
// marcel@palpatine:~/development/in-c$ node convert.js 


var fs = require('fs');
var midiConverter = require('midi-converter');

for (i = 1; i < 55; i++) { 
  var midiSong = fs.readFileSync('midi/' + i + '.mid', 'binary');
  var jsonSong = midiConverter.midiToJson(midiSong);
  fs.writeFileSync('app/assets/midi/' + i + '.json', JSON.stringify(jsonSong));
}


