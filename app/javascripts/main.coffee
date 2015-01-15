nop = (e) ->
  e.preventDefault()


class Ui
  constructor: (sequencer) ->
    @sequencer = sequencer
    @setupEvents()

    console.debug("yuoooo")
    console.debug($('#currentPattern'))

    $('#currentPattern').html(@sequencer.pattern)

  setupEvents: ->
    $('#next').on 'click', (e) =>
      nop(e)
      @sequencer.next()
      $('#currentPattern').html(@sequencer.pattern)
    # more ui events go here

class PeerSequencerUi
  constructor: (peerSequencer) ->
    @peerSequencer = peerSequencer

    $('#peerSequencers').append(JST['peerSequencer'](sequencer: peerSequencer))
    @setEvents()

  setEvents: () ->
    @peerSequencer.onUpdate = =>
      $('#s' + @peerSequencer.peerId).html(@peerSequencer.pattern)

class Sequencer

  constructor: ->
    @pattern = 1
    @play(@pattern)

  next: ->
    @pattern += 1
    @play(@pattern)
    
  play: (pattern) ->
    console.debug("start playing pattern")

class PeerSequencer extends Sequencer
  constructor: (peerId) ->
    super()
    # TODO get pattern number from peer with peerId 
    @peerId = peerId

    inC.firebase.child('patternFor' + peerId).on 'value', (value) =>
      @pattern = value
      @play(@pattern)
      if @onUpdate?
        @onUpdate()

class InC
  constructor: ->
    @firebase = new Firebase("blinding-heat-8749.firebaseio.com")

  broadcastPattern: ->
    @firebase.set sequencer.pattern, ->
      console.debug('done setting the value on firebase')


  loadMidis: ->
    console.debug("loadMidis")

  pickInstrument: ->
    console.debug("pickInstrument")

  startSoloSequencer: ->
    @soloSequencer = new Sequencer()
    @ui = new Ui(@soloSequencer)

  startGroupSequencer: ->

    # TODO 
    @peerIds = ['Vincent', 'Corne', 'Marcel']
    @peerSequencers = []
    @peerSequencerUis = []
    for peerId in @peerIds
      peerSequencer = new PeerSequencer(peerId)
      @peerSequencers.push(peerSequencer)
      @peerSequencerUis.push(new PeerSequencerUi(peerSequencer))

  startSequencer: ->
    console.debug("startSequencer")
    @startSoloSequencer()
    @startGroupSequencer()

  startPatternSharer: () ->
    console.debug("startPatternSharer")

  playSolo: ->
    console.debug("playSolo")

  go: ->
    @loadMidis()
    @pickInstrument()
    @startSequencer()
    @startPatternSharer()
    
    @playSolo()
  

$ ->
  console.log("DOM is ready")
  window.inC = new InC
  inC.go()


