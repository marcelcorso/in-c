nop = (e) ->
  e.preventDefault()


class Ui
  constructor: (sequencer) ->
    @sequencer = sequencer
    @setupEvents()

    console.debug($('#currentPattern'))

    $('#currentPattern').html(@sequencer.pattern)

  setupEvents: ->
    $('#next').on 'click', (e) =>
      nop(e)
      @sequencer.next()

      inC.firebase.child('patternFor' + inC.name).set(@sequencer.pattern, () -> console.log('value.set'))

      $('#currentPattern').html(@sequencer.pattern)

    $('#name').on 'change',  (e) =>
       inC.name = $('#name').val()

    # more ui events go here
    $('#playAll').on 'click', (e) =>
      for s in @peerSequencers
        s.start()
      for s in [@soloSequencer]
        s.stop()
 
    $('#playSolo').on 'click', (e) =>
      for s in @peerSequencers
        s.stop()
      for s in [@soloSequencer]
        s.start()
      

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
    @start()

  next: ->
    @pattern += 1

    @play(@pattern)
    
  play: (pattern) ->
    console.debug("if current playing, change to this pattern")

  start: ->
    console.debug("actually start playing")
    @tick = 0
    @timeoutHandle = setInterval( (=>
      index = (@tick % inC.score[@pattern].maxDeltaTime)
      if (index == 0)
        console.debug("----------------")
      notesOnTick = inC.score[@pattern].notesOnTick[index] || []
      for note in notesOnTick
        if note.subtype == 'noteOn'
          console.debug("on " + note.deltaTime + " play " + note.noteNumber)
          # PLAY note
        else if note.subtype == 'noteOff'
          # STOP PLAYING note
          console.debug("on " + note.deltaTime + " stop Play " + note.noteNumber)

      @tick += 1
    ), 100)


  stop: ->
    console.debug("stop playing")

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
    console.log('yolfsfsdfsd')
    @firebase = new Firebase("blinding-heat-8749.firebaseio.com")
    @firebase.authAnonymously( (error, authdata) ->
      console.log('Authed! ' + authdata)
    )

    
    @amOnline = new Firebase('https://blinding-heat-8749.firebaseio.com/.info/connected')
    @amOnline.on 'value', (snapshot) ->
      console.log('yolo + ' + snapshot)
    #   aPeerChanged(snapshot)

    @name = 'gimmeaname'

  aPeerChanged: (snapshot) ->
    if snapshot.val()
      peerCameOnline(snapshot)
    else
        peerWentOffline(snapshot)

  peerCameOnline: (peerID) ->
    console.log('Peer ' + peerID + ' came online.')

  peerWentOffline: (peerID) ->
    console.log('Peer ' + peerID +  'went offline')


  broadcastPattern: ->
    @firebase.set sequencer.pattern, ->
      console.debug('done setting the value on firebase')

  loadMidis: (callback) ->
    @score = {}
    @loaded = []
    for pattern in [1..53]
      @load1Midi(pattern, callback)
          
  load1Midi: (pattern, callback) ->
    $.getJSON '/midi/' + pattern + '.json', (data) =>
      notesOnTick = {}
      maxDeltaTime = 0

      $.each data.tracks[0], (i, note) ->
        if note.subtype == 'noteOn' or note.subtype == 'noteOff'
          notesOnTick[note.deltaTime] = [] unless notesOnTick[note.deltaTime]?
          notesOnTick[note.deltaTime].push(note)
          if note.deltaTime > maxDeltaTime
            maxDeltaTime = note.deltaTime

      @score[pattern] = {maxDeltaTime: maxDeltaTime, notesOnTick: notesOnTick}

      @loaded.push(pattern)
      if _.size(@loaded) == 53
        callback()



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
    # @startGroupSequencer()

  startPatternSharer: () ->
    console.debug("startPatternSharer")

  playSolo: ->
    console.debug("playSolo")

  go: ->
    @loadMidis =>
      # @pickInstrument()
      @startSequencer()
      # @startPatternSharer()
      
      # @playSolo()
  

$ ->
  console.log("DOM is ready")
  window.inC = new InC
  inC.go()


