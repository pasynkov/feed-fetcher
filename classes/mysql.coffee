
mysql = require "mysql"
_ = require "underscore"
async = require "async"


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

    @client.query "INSERT INTO ?? (??) VALUES ?", [tableName, names, rows], callback

  insertRowsByOne: (tableName, rows, callback)->

    async.map(
      rows
      (row, done)=>
        @client.query "INSERT INTO ?? SET ?", [tableName, row], done
      callback
    )

  find: (tableName, where, callback)=>

    keys = _.map(
      _.keys(where)
      (key, i)->
        return "#{key} = ?"
    ).join " AND "

    @client.query "SELECT * FROM ?? WHERE #{keys}", _.flatten([tableName, _.values(where)]), callback

module.exports = Mysql