var fireRef = new FireBase("blinding-heat-8749.firebaseio.com")


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

class Sequencer

  constructor: ->
    @pattern = 1
    @play(@pattern)

  next: ->
    @pattern += 1
    @play(@pattern)
    

  play: (pattern) ->
    console.debug("start playing pattern")

class InC
  constructor: ->
    console.debug("akjas")

  initFB: ->
    fireRef.set("test") 

  broadcastPattern: ->
    fireRef.(sequencer.pattern)



  loadMidis: ->
    console.debug("loadMidis")

  pickInstrument: ->
    console.debug("pickInstrument")

  startSoloSequencer: ->
    @soloSequencer = new Sequencer()
    @ui = new Ui(@soloSequencer)

  startSequencer: ->
    console.debug("startSequencer")
    @startSoloSequencer()
    # TODO @startGroupSequencer()

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
  inC = new InC
  inC.go()


