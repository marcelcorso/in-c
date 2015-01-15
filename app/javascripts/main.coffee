nop = (e) ->
  e.preventDefault()


class Ui
  constructor: (sequencer) ->
    @sequencer = sequencer
    @setupEvents()

    console.debug($('#currentPattern'))

    $('#currentPattern').html(@sequencer.pattern)

  setupEvents: () =>
    $('#next').on 'click', (e) =>
      nop(e)
      @sequencer.next()

      inC.firebase.child('users').child(inC.authid).child('pattern').set(@sequencer.pattern, () -> console.log('value.set'))  
      
      $('#currentPattern').html(@sequencer.pattern)

    $('#name').on 'change',  (e) =>
      inC.changedName($('#name').val())
      
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

  setEvents: () =>
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
      console.debug("yo:" + @pattern)
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
          console.debug("on " + note.deltaTime + " stop " + note.noteNumber)

      @tick += 1
    ), 10000)


  stop: ->
    console.debug("stop playing")

class PeerSequencer extends Sequencer
  constructor: (peerId) ->
    super()
    # TODO get pattern number from peer with peerId 
    @peerId = peerId

    console.debug(peerId)
    inC.firebase.child('users').child(peerId).once 'value', (value) =>
      console.debug("ni: ")
      console.debug(value.val() )
      @pattern = value.val()
      @play(@pattern)
      if @onUpdate?
        @onUpdate()

class InC

  constructor: ->
    
    @peerSequencers = []
    @peerSequencerUis = []

    @firebase = new Firebase("blinding-heat-8749.firebaseio.com")
    @firebase.authAnonymously( (error, authdata) =>
      console.log('Authed! ' + authdata.uid)
      @authid = authdata.uid
      @firebase.child('users').child(@authid).child('pattern').set(1).onDisconnect().remove()
      
      
    )

    @firebase.child("users").on("child_changed", (snapshot) =>
      peer = snapshot.key()
      pattern = snapshot.val()

      console.log("peer " + peer + "changed pattern")
      
      for s in @peerSequencerUis
        if s.peerSequencer.PeerId == peer
          s.peerSequencer.pattern = pattern
          s.setEvents() 




    )

    @amOnline = new Firebase('https://blinding-heat-8749.firebaseio.com/.info/connected')
    @amOnline.on 'value', (snapshot) =>
      console.log('yolo + ' + snapshot)
      @aPeerChanged(snapshot)

  changedName: (name) ->
    @name = name
    console.debug("changedname: " + name + "authid: " + @authid)
    ref = @firebase.child('users').child(@authid).child('name').set(name)
   #  ref.onDisconnect().remove()


  aPeerChanged: (snapshot) ->
    if snapshot.val() 
      @peerCameOnline(snapshot)
    else
      @peerWentOffline(snapshot)

  peerCameOnline: (peerID) ->
    console.log('Peer ' + peerID.val() + ' came online.')

  peerWentOffline: (peerID) ->
    console.log('Peer ' + peerID.val() +  'went offline')


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
    # console.debug('fdsfds')
    # console.debug(@firebase.child('users').val())

    peers = @firebase.child('users').once('value', (snapshot) => 
      snapshot.forEach((childSnapshot) => 
        console.debug('key : ' + childSnapshot.key() +  " value: " + childSnapshot.val())
        peerkey = childSnapshot.key()
        peerSequencer = new PeerSequencer(peerkey)
        console.debug(peerSequencer)
        @peerSequencers.push(peerSequencer)
        @peerSequencerUis.push(new PeerSequencerUi(peerSequencer))
        )
      )
    
    
    
    # for peerId in @peerIds
    #   peerSequencer = new PeerSequencer(peerId)
    #  @peerSequencers.push(peerSequencer)
    # @peerSequencerUis.push(new PeerSequencerUi(peerSequencer))

  startSequencer: ->
    console.debug("startSequencer")
    @startSoloSequencer()
    @startGroupSequencer()

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


