
# loadMidis
#

class InC
  constructor: ->
    console.debug("akjas")

  loadMidis: ->
    console.debug("loadMidis")

  pickInstrument: ->
    console.debug("pickInstrument")

  startSequencer: ->
    console.debug("startSequencer")

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
  

inC = new InC
inC.go()


