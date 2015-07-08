
defaulConfig = require "../config/config.json"

DefaultFeedFetcher = require "../fetchers/default_fetcher"
Mysql = require "./mysql"

winston = require "winston"
async = require "async"
_ = require "underscore"

class Core

  constructor: ->

    @config = defaulConfig

    @loggers = {}

    @logger = @createLogger(
      {
        name: "main"
        options:
          console:
            level: "info"
            label: "Main"
            colorize: true
      }
    )



  initialize: (callback)->

    initializers = []

    @mysql = new Mysql

    if @config.mysql
      initializers.push @mysql.connect

    @logger.info "Start initialize FeedFetcher"

    async.parallel initializers, callback


  createLogger: (loggerOpts)->

    @loggers[loggerOpts.name] = winston.loggers.add loggerOpts.name, loggerOpts.options

    return @loggers[loggerOpts.name]

  fetchFeeds: (callback)->

    @logger.info "Start feeds fetching"

    unless @config.fetcher?.feeds?.length
      return callback "Not feeds available in config"

    @logger.info "Start fetch for all feeds"

    async.parallel(
      _.mapObject(
        _.indexBy(
          @config.fetcher.feeds
          (config)-> config.name
        )
        (feed)->
          (taskCallback, done)->

            FeedFetcher = DefaultFeedFetcher

            if feed.fetcher
              try
                FeedFetcher = require "../fetchers/#{feed.fetcher}"
              catch e
                return done "Require fetcher `#{feed.fetcher}` failed with err `#{e}`"

            (new FeedFetcher feed.name, feed.link).fetch done
      )
      callback
    )


module.exports = Core