window.context = new webkitAudioContext()

class Player
  constructor: (options) ->
    @filterValue = options['filterValue'] || (Math.random() * 10000) + 300
    @waveform = options['waveform'] || Math.round((Math.random() * 3))
    @length = options['length'] || (Math.random() * 2)
    @register = options['register'] || Math.round((Math.random() * 7))
    @active_voices = {}
    
  noteOn: (note) ->
    voice = new Voice(note, @filterValue, waveform(@waveform), @length, @register)
    voice.start()

class Voice
  constructor: (note, filterValue, waveform, length, register) ->
    @frequency = midiToFreq(note, register)
    @filterValue = filterValue
    @waveform = waveform
    @length = length
    @register = register
    @oscillators = []

  start: ->
    vco = context.createOscillator()
    vco.type = @waveform
    vco.frequency.value = @frequency
    vca = context.createGain()
    vca.gain.value = 0.3

    now = context.currentTime
    vca.gain.cancelScheduledValues(now)
    vca.gain.setValueAtTime(vca.gain.value, now)
    vca.gain.linearRampToValueAtTime(0 , now + @length)

    filter = context.createBiquadFilter()
    filter.type = 'lowpass'
    filter.frequency.value = @filterValue

    vco.connect(vca)
    vca.connect(filter)
    filter.connect(context.destination)

    vco.start(0)

    @oscillators.push(vco)

window.waveform = (id) ->
  waveforms = ["sine", "square", "sawtooth", "triangle"]
  waveforms[id]

window.midiToFreq = (note, register) ->
  notes = { C: 36, D: 38, E: 40, F: 41, G: 43, A: 45, B: 47 }
  440.0 * Math.pow(2, ((notes[note] + (register * 12)) - 69) / 12)


