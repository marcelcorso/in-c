window.context = new webkitAudioContext()

class Player
  constructor: ->
    @filterValue = (Math.random() * 10000) + 300
    @active_voices = {}
    
  noteOn: (note, frequency) ->
    voice = new Voice(frequency, @filterValue)
    voice.start()

  noteOff: (note) ->
    @active_voices[note].stop()
    delete @active_voices[note]


class Voice
  constructor: (frequency, filterValue) ->
		@frequency = frequency
		@filterValue = filterValue
		@oscillators = []

	start: ->
		vco = context.createOscillator()
		vco.type = "square"
		vco.frequency.value = @frequency
    vca = context.createGain()
	  vca.gain.value = 0.3

		now = context.currentTime
	  vca.gain.cancelScheduledValues(now)
		vca.gain.setValueAtTime(vca.gain.value, now)
		vca.gain.linearRampToValueAtTime(0 , now + 1)

		filter = context.createBiquadFilter()
		filter.type = 'lowpass'
		filter.frequency.value = @filterValue

		vco.connect(vca)
		vca.connect(filter)
		filter.connect(context.destination)

	 	vco.start(0)

	  @oscillators.push(vco)
	
	stop: ->
    _.each @oscillators, (o) ->
      o.stop()

window.noteToFreq = (note) ->
	Math.pow(2, (note - 69) / 12) * 440
