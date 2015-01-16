
nop = (e) ->
  e.preventDefault()

cleanId = (id) ->
  id.replace('anonymous:-', '')

class Ui
  constructor: (sequencer) ->
    @sequencer = sequencer
    @setupEvents()

    $('#currentPattern').html(@sequencer.pattern)
    $('#name').val(@sequencer.name)

  setupEvents: () =>
    $('#next').on 'click', (e) =>
      nop(e)
      @sequencer.next()
      inC.firebase.child('users').child(inC.authid).child('pattern').set(@sequencer.pattern)
      $('#currentPattern').html(@sequencer.pattern)

    $('#name').on 'change',  (e) =>
      @sequencer.name = $('#name').val()
      inC.firebase.child('users').child(inC.authid).child('name').set(@sequencer.name)

      
    # more ui events go here
    $('#playAll').on 'click', (e) =>
      for k, v of inC.peerSequencers
        v.start()
      inC.soloSequencer.stop()
 
    $('#playSolo').on 'click', (e) =>
      for k, v of inC.peerSequencers
        v.stop()
      inC.soloSequencer.start()
      

class PeerSequencerUi
  constructor: (peerSequencer) ->
    @peerSequencer = peerSequencer
    $('#peerSequencers').append(JST['peerSequencer'](sequencer: peerSequencer))

  remove: () ->
    $('#holder' + cleanId(@peerSequencer.id)).remove()
    
  refresh: () ->
    $('#s' + cleanId(@peerSequencer.id)).html(@peerSequencer.pattern)
    $('#n' + cleanId(@peerSequencer.id)).html(@peerSequencer.name)

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
          console.debug("on " + note.delta + " play " + note.name)
          @player.noteOn(note.name)
          # PLAY note
        else if note.subtype == 'noteOff'
          # STOP PLAYING note
          console.debug("on " + note.delta + " stop " + note.name)
          # noteOff(note.name);

      @tick += 1
    ), 20)

  stop: ->
    console.debug("stop playing")
    clearTimeout(@timeoutHandle)

class InC

  constructor: ->
    @firebase = new Firebase("blinding-heat-8749.firebaseio.com")

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
        
  createSequencerForUser: (user) ->
    id = user.key()
    peerPattern = user.child('pattern').val()
    peerName = user.child('name').val()
    peerSequencer = new Sequencer(id, peerName)
    peerSequencer.player = new Player(
        filterValue: user.child('playerFilterValue').val(),
        waveform: user.child('playerWaveform').val(),
        lenght:  user.child('playerLength').val(),
        register:  user.child('playerRegister').val()
    )

    @peerSequencers[id] = peerSequencer
    @peerSequencerUis[id] = new PeerSequencerUi(peerSequencer)

  buildGroupSequencer: ->
    @peerSequencers = {}
    @peerSequencerUis = {}
    # create all peer sequencers
    
    # @firebase.child('users').once('value', (users) =>
    #  console.debug('users once value')
    #  users.forEach((user) =>
    #    @createSequencerForUser(user)
    #    )
    #  )

    # watch for changes on the user data
    @firebase.child('users').on('child_changed', (user) =>
      sequencer = @peerSequencers[user.key()]
      sequencer.name = user.child('name').val()
      sequencer.pattern = user.child('pattern').val()
      @peerSequencerUis[user.key()].refresh()
    )

    @firebase.child('users').on('child_added', (user) =>
      # create a new sequencer
      @createSequencerForUser(user)
    )

    @firebase.child('users').on('child_removed', (user) =>
      sequencer = @peerSequencers[user.key()]
      sequencer.stop()
      @peerSequencerUis[user.key()].remove()

      delete @peerSequencers[user.key()]
      delete @peerSequencerUis[user.key()]
    )

  go: ->
    console.debug("go()")
    @firebase.authAnonymously( (error, authdata) =>
      console.log('Authed! ' + authdata.uid)
      @authid = authdata.uid

      console.debug("startSoloSequencer:")
      @soloSequencer = new Sequencer(@authid, Math.random())
      @soloSequencer.player = new Player({})
      @ui = new Ui(@soloSequencer)

      # save to firebase
      data = {
        pattern: @soloSequencer.pattern,
        name: @soloSequencer.name,
        playerFilterValue: @soloSequencer.player.filterValue,
        playerWaveForm: @soloSequencer.player.waveform,
        playerLenght: @soloSequencer.player.length,
        playerRegister: @soloSequencer.player.register
      }
    
      @firebase.child('users').child(@authid).set(data)

      @fbuserref = new Firebase("blinding-heat-8749.firebaseio.com/users/" + @authid)
      @fbuserref.onDisconnect().remove()

      # load patterns from json
      @loadNewPatterns =>
        @buildGroupSequencer()
        @soloSequencer.start()
    )

$ ->
  console.log("DOM is ready")
  window.inC = new InC
  inC.go()


