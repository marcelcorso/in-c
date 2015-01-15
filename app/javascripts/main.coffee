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

      inC.firebase.child('patternIndexes').child(inC.name).set(@sequencer.pattern, () -> console.log('value.set'))

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
    @play(@pattern)

  next: ->
    @pattern += 1

    @play(@pattern)
    
  play: (pattern) ->
    console.debug("if current playing, change to this pattern")

  start: ->
    console.debug("actually start playing")

  stop: ->
    console.debug("stop playing")

class PeerSequencer extends Sequencer
  constructor: (peerId) ->
    super()
    # TODO get pattern number from peer with peerId 
    @peerId = peerId

    inC.firebase.child('patternIndexes').child('patternFor' + peerId).on 'value', (value) =>
      @pattern = value
      @play(@pattern)
      if @onUpdate?
        @onUpdate()





class InC

  constructor: ->
    console.log('yolfsfsdfsd')
    @firebase = new Firebase("blinding-heat-8749.firebaseio.com")
    @firebase.authAnonymously( (error, authdata) =>
      console.log('Authed! ' + authdata.uid)
      
    )

    @firebase.child("patternIndexes").on("child_changed", (snapshot) =>
      peer = snapshot.key()
      pattern = snapshot.val()

      console.log("peer " + peer + "changed to pattern " + pattern)

      ) 
    

    @amOnline = new Firebase('https://blinding-heat-8749.firebaseio.com/.info/connected')
    @amOnline.on('value', (snapshot) =>

      console.log('yolo + ' + snapshot)
      @aPeerChanged(snapshot)
    )



  changedName: (name) ->
    @name = name
    ref = @firebase.child('users').push(name)
    ref.onDisconnect().remove()


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


