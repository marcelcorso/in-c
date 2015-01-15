var context = new webkitAudioContext();

var Player = (function(context) {

	function Player(id) {

		this.filterValue = (Math.random() * 10000) + 300;
		this.envelope = (Math.random() * 2);
	}

	return Player;

})(context);

var Voice = (function(context) {

	function Voice(frequency, filterValue) {

		this.frequency = frequency;
		this.filterValue = filterValue;
		this.oscillators = [];
	};

	Voice.prototype.start = function() {

		var vco = context.createOscillator();
		vco.type = "square";
		vco.frequency.value = this.frequency;

	 	var vca = context.createGain();
	   	vca.gain.value = 0.3;

		var now = context.currentTime;
	    vca.gain.cancelScheduledValues(now);
		vca.gain.setValueAtTime(vca.gain.value, now);
		vca.gain.linearRampToValueAtTime(0 , now + (Math.random() * 2));

		var filter = context.createBiquadFilter();
		filter.type = 'lowpass';
		filter.frequency.value = this.filterValue;

		vco.connect(vca);
		vca.connect(filter);
		filter.connect(context.destination);

	 	vco.start(0);

	   	this.oscillators.push(vco);
	};
	/*
	Voice.prototype.stop = function() {

	 	this.oscillators.forEach(function(oscillator, _) {

	 		oscillator.stop();
		});
	}; */

	return Voice;

})(context);

/*
function noteOff(note, _) {
  
  	active_voices[note].stop();
  	delete active_voices[note];
};
*/

function newPlayer(id) {

	var player = new Player(id);
}

function noteOn(frequency) {

	var voice = new Voice(frequency, (Math.random() * 10000) + 300);
    voice.start();
}

function noteToFreq(note) {

	return Math.pow(2, (note-69)/12)*440;
}

setInterval(playNote, 200);

function playNote() {

	noteOn(noteToFreq(40));
}