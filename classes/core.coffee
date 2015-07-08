
defaulConfig = require "../config/config.json"

winston = require "winston"

class Core

  constructor: ->

    @config = defaulConfig

    @loggers = {}

    @logger = @createLogger(
      {
        name: "main"
        console:
          level: "info"
          label: "Main"
          colorize: true
      }
    )


  initialize: (callback)->

    @logger.info "Start initialize FeedFetcher"

    callback()


  createLogger: (loggerOpts)->

    @loggers[loggerOpts.name] = winston.loggers.add loggerOpts.name, loggerOpts.options

    return @loggers[loggerOpts.name]


module.exports = Core