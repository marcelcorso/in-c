window.context = new webkitAudioContext()

class Player
  constructor: ->
    @filterValue = (Math.random() * 10000) + 300
    @waveform = Math.round((Math.random() * 3))
    @length = (Math.random() * 2) + 1
    @register = Math.round((Math.random() * 7))
    @active_voices = {}
    
  noteOn: (note, frequency) ->
    voice = new Voice(frequency, @filterValue, waveform(@waveform), @length, @register)
    voice.start()

class Voice
  constructor: (frequency, filterValue, waveform, length, register) ->
    @frequency = transpose(frequency, register)
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

window.transpose = (frequency, register) ->
    frequency * register

window.noteToFreq = (note) ->
    (Math.pow(2, (note - 69) / 12) * 440) / 4
