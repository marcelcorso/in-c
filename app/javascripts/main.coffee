
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
  constructor: (id, name) ->
    @id = id
    @name = name
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
        4+7 # console.debug("----------------")
      notesOnTick = inC.score[@pattern].notesOnTick[index] || []
      for note in notesOnTick
        if note.subtype == 'noteOn'
<<<<<<< HEAD
          console.debug("on " + note.delta + " play " + note.name)
          @player.noteOn(note.name)
          # PLAY note
=======
          1+2
          # TODO console.debug("on " + note.delta + " play " + note.name)
          # TODO @player.noteOn(note.name, noteToFreq(note.name))
>>>>>>> c5cdbdba96e8b56356aaa9190aef13a89bc17752
        else if note.subtype == 'noteOff'
          # STOP PLAYING note
          # TODO console.debug("on " + note.delta + " stop " + note.name)
          # TODO noteOff(note.name);
          4+3

      @tick += 1
    ), 20)

  stop: ->
    console.debug("stop playing")

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

  changedName: (name) ->
    @name = name
    console.debug("changedname: " + name + "authid: " + @authid)
    ref = @firebase.child('users').child(@authid).child('name').set(name)
   #  ref.onDisconnect().remove()


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
        
  startSoloSequencer: ->
    console.debug("startSoloSequencer:")
    @soloSequencer = new Sequencer('439872432', 'solo')
    @soloSequencer.player = new Player()
    @soloSequencer.start()
    @ui = new Ui(@soloSequencer)

  createSequencerForUser: (user) ->
    peerId = user.key()
    peerPattern = user.child('pattern').val()
    peerName = user.child('name').val()
    peerSequencer = new Sequencer(peerId, peerName)
    @peerSequencers[peerId] = peerSequencer
    @peerSequencerUis[peerId] = new PeerSequencerUi(peerSequencer)


  startGroupSequencer: ->
    @peerSequencers = {}
    @peerSequencerUis = {}
    # create all peer sequencers
    @firebase.child('users').once('value', (users) =>
      users.forEach((user) =>
        @createSequencerForUser(user)
        )
      )

    # watch for changes on the user data
    @firebase.child('users').on('child_changed', (user) =>
      sequencer = @peerSequencers[user.key()]
      sequencer.name = childSnapshot.child('name').val()
      sequencer.pattern = childSnapshot.child('pattern').val()
      sequencer.player = new Player()
    )

    @firebase.child('users').on('child_added', (user) =>
      console.debug('child added')
      # create a new sequencer
      @createSequencerForUser(user)
    )

    @firebase.child('users').on('child_removed', (childSnapshot) =>
      sequencer = @peerSequencers[user.key()]
      sequencer.stop()
      delete @peerSequencers[user.key()]
    )

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
      @startSequencer()

$ ->
  console.log("DOM is ready")
  window.inC = new InC
  inC.go()


