
defaulConfig = require "../config/config.json"

DefaultFeedFetcher = require "../fetchers/default_fetcher"
Mysql = require "./mysql"
WebServer = require "./web_server"

winston = require "winston"
path = require "path"
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

    @webServer = new WebServer

    if @config.mysql
      initializers.push @mysql.connect

    if @config.cron
      initializers.push @createCronTask(@config.cron)



    if @config.webServer
      initializers.push @webServer.start

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

  readFileIfExists: (path, callback)=>

    fs.exists path, (exists)->
      if exists
        fs.readFile path, encoding: "utf8", callback
      else
        callback "File is not exists"

  getItems: (skip, limit, callback)=>

    if @mysql.connected()

      @getItemsFromMysql skip, limit, callback

    else

      @getItemsFromStatic skip, limit, callback

  getItemsFromMysql: (skip, limit, callback)=>

    async.parallel(
      {
        items: (taskCallback)=>
          @mysql.client.query "SELECT * FROM items ORDER BY created DESC LIMIT #{skip},#{limit}", taskCallback
        count: (taskCallback)=>
          @mysql.client.query "SELECT count(*) as count FROM items", taskCallback
      }
      (err, {items, count})=>
        callback err, {
          items: items?[0]
          count: count?[0]?[0]?.count
        }
    )

  getItemsFromStatic: (skip, limit, callback)=>
    async.waterfall(
      [
        async.apply fs.readdir, path.join(__dirname, "..", core.config.fetcher.staticDir)
        (files, taskCallback)->
          taskCallback null, {
            items: _.sortBy(
              _.map(
                files
                (file)->
                  item = require path.join(__dirname, "..", core.config.fetcher.staticDir, file)
                  item.id = file.replace(".json", "")
                  return item
              )
              (item)->
                return new Date(item.created)
            )[skip...(limit + skip)]
            count: files.length
          }
      ]
      callback
    )

  getItem: (id, callback)=>
    if @mysql.connected()
      @mysql.find "items", {id}, (err, [item])=>
        if err
          @logger.error "getItem crash with err: `#{err}`"
        callback err, item
    else
      @readFileIfExists path.join(__dirname, "..", core.config.fetcher.staticDir, id + ".json"), (err, content)->
        unless err
          try
            content = JSON.parse content
          catch
            err = "Cannot parse file"
        callback err, content

  saveSettings: (callback)=>
    fs.writeFile path.join(__dirname, "..", "config/config.json"), JSON.stringify(@config, "    ", "    "), encoding: "utf8", callback


module.exports = Core