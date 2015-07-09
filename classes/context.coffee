
_ = require "underscore"

class Context

  constructor: (@requester, @responser, @controllerName, @action)->

    @logger = core.createLogger(
      {
        name: "context"
        options:
          console:
            level: "info"
            colorize: "true"
            label: "Context"
      }
    )


    @logger.info "incoming request to `#{@requester.url}`. Run controller `#{@controllerName}` with action `#{@action}`"

  sendData: (err, data)=>
    if err
      @responser.status 404

      if _.isObject(data)
        data = {
          error: err
        }

      @logger.error err

    @responser.send data

module.exports = Context