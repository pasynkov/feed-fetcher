class MainController


  constructor: (@context)->


  index: ->
    @context.responser.send "hello"

module.exports = MainController