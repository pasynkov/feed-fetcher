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

module.exports = Context