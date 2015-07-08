
mysql = require "mysql"
_ = require "underscore"


class Mysql

  constructor: ->

    @config = core.config.mysql

    @logger = core.createLogger(
      name: "mysql"
      options:
        console:
          level: "info"
          colorize: true
          label: "Mysql"
    )

    @client = mysql.createConnection @config


  connect: (callback)=>

    @logger.info "Start connect"

    @client.connect (err)=>
      if err

        @logger.error "Connection failed with error: `#{err}`"

      else

        @logger.info "Connected successfully"

      callback err

  connected: ->
    return @client.state is "authenticated"


  insertRows: (tableName, rows, callback)->

    names = _.keys rows[0]

    rows = _.map(
      rows
      (row)->
        _.map(
          names
          (name)->
            row[name]
        )
    )

    query = @client.query "INSERT INTO ?? (??) VALUES ?", [tableName, names, rows], (err)->
      console.log err



module.exports = Mysql