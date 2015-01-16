
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
      # console.debug("index: " + index)
      if (index == 0)
        console.debug("----------------")
      notesOnTick = inC.score[@pattern].notesOnTick[index] || []
      for note in notesOnTick
        if note.subtype == 'noteOn'
          console.debug("on " + note.delta + " play " + note.name)
          @player.noteOn(note.name, noteToFreq(note.name))
          # PLAY note
        else if note.subtype == 'noteOff'
          # STOP PLAYING note
          console.debug("on " + note.delta + " stop " + note.name)
          # noteOff(note.name);

      @tick += 1
    ), 20)

  stop: ->
    console.debug("stop playing")

class PeerSequencer extends Sequencer
  constructor: (peerId, pattern) ->
    super()
    # TODO get pattern number from peer with peerId 
    @peerId = peerId
    @pattern = pattern
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
      delref = @firebase.child('users').child(@authid).child('pattern').set(1)
      
      
      

    )

    @firebase.child("users").on("child_changed", (snapshot) =>
      peer = snapshot.key()
      pattern = snapshot.val()
      console.log("Peer " + peer + " with name "+ snapshot.child('name').val() + " changed pattern")

      found = false

      for sequencerui in @peerSequencerUis
        if sequencerui.peerSequencer.peerId is peer
          sequencerui.peerSequencer.pattern = pattern
          found = true

      if !found 
        peersequencerui = new PeerSequencerUi(new PeerSequencer(peer, pattern))
        @peerSequencerUis.push(peersequencerui)
        peersequencerui
        
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

  loadNewPatterns: (callback) ->
    @score = {}
    @rawScore = {}
    # thanks https://github.com/sbma44/in_c_in_python
    $.getJSON '/InC.json', (data) =>
      $.each data, (pattern, notes) =>
        delta = 0
        @rawScore[pattern] = []
        notesOnTick = {}
        $.each notes, (i, arr) =>
          note = {
            name: arr[0],
            octave: arr[1],
            dynamics: arr[2],
            duration: arr[3],
            is_rest: arr[4]
          }
          @rawScore[pattern].push(note)
          notesOnTick[delta] = [] unless notesOnTick[delta]?
          noteOn = $.extend({subtype: 'noteOn', delta: delta}, note)
          notesOnTick[delta].push(noteOn)
          
          delta += (note.duration * 10)

          noteOffDelta = delta - 4 # -4 is to give a rest before the next note
          noteOff = $.extend({subtype: 'noteOff', delta: noteOffDelta}, note)
          notesOnTick[noteOffDelta] = [] unless notesOnTick[noteOffDelta]?
          notesOnTick[noteOffDelta].push(noteOff)
      
        @score[pattern] = {maxDeltaTime: delta, notesOnTick: notesOnTick}

      callback()
        
  pickInstrument: ->
    console.debug("pickInstrument")

  startSoloSequencer: ->
    console.debug("startSoloSequencer:")
    @soloSequencer = new Sequencer()
    @soloSequencer.player = new Player()
    @soloSequencer.start()
    @ui = new Ui(@soloSequencer)

  startGroupSequencer: ->
    
    # TODO
    # console.debug('fdsfds')
    # console.debug(@firebase.child('users').val())

    peers = @firebase.child('users').once('value', (snapshot) => 
      snapshot.forEach((childSnapshot) => 
        console.debug('key : ' + childSnapshot.key() +  " value: " + childSnapshot.val())
        peerkey = childSnapshot.key()
        peerPattern = childSnapshot.child('pattern').val()
        console.debug('peerPattern: ' + peerPattern)
        peerSequencer = new PeerSequencer(peerkey, )
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
    console.debug("go()")
    @loadNewPatterns =>
      # @pickInstrument()
      @startSequencer()
      # @startPatternSharer()
      
      # @playSolo()
  

$ ->
  console.log("DOM is ready")
  window.inC = new InC
  inC.go()


