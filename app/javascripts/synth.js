var context = new webkitAudioContext();

var Voice = (function(context) {

	function Voice(frequency) {

	    this.frequency = frequency;
	    this.oscillators = [];
	};

		Voice.prototype.start = function() {

	   		var vco = context.createOscillator();
	   		vco.type = "sawtooth";
	    	vco.frequency.value = this.frequency;

 		   	var vca = context.createGain();
    		vca.gain.value = 0.3;

	    	vco.connect(vca);
	    	vca.connect(context.destination);

	    	var now = context.currentTime;
            vca.gain.cancelScheduledValues(now);
			vca.gain.setValueAtTime(vca.gain.value, now);
			vca.gain.linearRampToValueAtTime(0 , now + 0.9);

 		   	vco.start(0);

   			this.oscillators.push(vco);
		};

		Voice.prototype.stop = function() {

 	  		this.oscillators.forEach(function(oscillator, _) {

 		   		oscillator.stop();
			});
	};

	return Voice;

})(context);

active_voices = {};

function noteOn(note, frequency, length) {

	var voice = new Voice(frequency);
    active_voices[note] = voice;
    voice.start();
}

function noteOff(note, _) {
  
  	active_voices[note].stop();
  	delete active_voices[note];
};

function onMIDIMessage( event ) {
  var str = "MIDI message received at timestamp " + event.timestamp + "[" + event.data.length + " bytes]: ";
  for (var i=0; i<event.data.length; i++) {
    str += "0x" + event.data[i].toString(16) + " ";
  }
  console.log( str );
}

function startLoggingMIDIInput( midiAccess, indexOfPort ) {
  midiAccess.inputs.entries[indexOfPort].onmidimessage = onMIDIMessage;
}


noteOn(0, 400, 200);
noteOn(1, 600, 200);
noteOn(3, 800, 200);