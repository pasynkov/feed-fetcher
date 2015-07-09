
express = require "express"
bodyParser = require "body-parser"

Context = require "./context"
router = require "../config/router"

path = require "path"

class WebServer

  constructor: ->

    @server = express()

    @server.use bodyParser.urlencoded(extended: true)

    @config = core.config.webServer

    @logger = core.createLogger(
      {
        name: "webServer"
        options:
          console:
            level: "info"
            colorize: "true"
            label: "WebServer"
      }
    )

    router.call @


  addRoute: (method, route, controllerName, action)->
    @server[method] route, (req, res)->
      Controller = require path.resolve ".", "controllers", controllerName
      context = new Context req, res, controllerName, action
      controller = new Controller context
      controller[action]()


  start: (callback)=>
    @server.listen @config.port, =>
      @logger.info "Start listen port `#{@config.port}`"
      callback()



module.exports = WebServer