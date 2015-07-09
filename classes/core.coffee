
defaulConfig = require "../config/config.json"

DefaultFeedFetcher = require "../fetchers/default_fetcher"
Mysql = require "./mysql"

winston = require "winston"
async = require "async"
_ = require "underscore"
CronJob = require("cron").CronJob

fs = require "fs"

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

    if @config.cron
      for task in @config.cron
        initializers.push @createCronTask(task)

    @logger.info "Start initialize FeedFetcher"

    async.parallel initializers, callback

  createCronTask: (config)->

    @logger.info "Add cron task `#{config.script}`"

    return (taskCallback)=>
      new CronJob({
        cronTime: config.runOn
        onTick: =>

          @logger.info "Start cron task `#{config.script}`"

          try
            script = new (require "../scripts/#{config.script}")
          catch e
            @logger.error "Cron task `#{config.script}` fail with err: `#{e}`"

          script.invoke (err)=>
            if err
              @logger.error "Cron task `#{config.script}` fail with err: `#{err}`"
            else
              @logger.info "Cron task `#{config.script}` successfully completed"

        start: false
        timeZone: "Europe/Moscow"
      }).start()

      taskCallback()

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

  checkDirectory: (path, callback)=>

    async.waterfall(
      [
        (taskCallback)->
          fs.exists path, (exists)->
            if exists
              fs.lstat path, taskCallback
            else
              fs.mkdir path, (err)->
                if err
                  taskCallback err
                else
                  fs.lstat path, taskCallback
        (stat, taskCallback)->
          if stat.isDirectory()
            taskCallback()
          else
            taskCallback "`#{path}` must be a directory"
      ]
      callback
    )


module.exports = Core