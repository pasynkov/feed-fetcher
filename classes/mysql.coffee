
mysql = require "mysql"
_ = require "underscore"
async = require "async"

###*
Класс-фетчер. Родительский класс для остыльных фетчеров. Умеет доставать и сохранять новости
@class Mysql
@constructor
###
class Mysql


  ###*
  Конструктор класса
  @method constructor
  ###
  constructor: ->


    ###*

    Конфиг mysql

    @property config
    @type {Object}
    ###
    @config = core.config.mysql

    ###*

    Логгер

    @property logger
    @type {Object}
    ###
    @logger = core.createLogger(
      name: "mysql"
      options:
        console:
          level: "info"
          colorize: true
          label: "Mysql"
    )

    ###*

    MySQL-клиент

    @propery client
    @type {Object}
    ###
    @client = mysql.createConnection @config


  ###*

  Коннектится к базе из конфига

  @method connect
  @param callback {Function}
  @param callback.error {String|null} возвращает строку с ошибкой или `null`
  @async
  ###
  connect: (callback)=>

    @logger.info "Start connect"

    @client.connect (err)=>
      if err

        @logger.error "Connection failed with error: `#{err}`"

        callback err

      else

        @logger.info "Connected successfully"

        core.readFileIfExists "./src/item.sql", (err, sql)=>
          if err
            callback err
          else
            @client.query sql, callback


  ###*

  Проверяет есть ли коннект к базе

  @method connected
  @return result {Boolean} результат запроса
  ###
  connected: ->
    return @client.state is "authenticated"


  ###*

  Сохраняет массив объектов в базе

  @method insertRows
  @param tableName {String} имя таблицы
  @param rows {Array} массив объектов для инсерта
  @param callback {Function}
  @param callback.error {String|null} возвращает строку с ошибкой или `null`
  @async
  ###
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

  ###*

  Сохраняет массив объектов в базе, причем по одному

  @method insertRowsByOne
  @param tableName {String} имя таблицы
  @param rows {Array} массив объектов для инсерта
  @param callback {Function}
  @param callback.error {String|null} возвращает строку с ошибкой или `null`
  @async
  ###
  insertRowsByOne: (tableName, rows, callback)->

    async.map(
      rows
      (row, done)=>
        @client.query "INSERT INTO ?? SET ?", [tableName, row], done
      callback
    )

  ###*

  Совершает `SELECT`-запрос к базе и достает записи по запросу `where`

  @method find
  @param tableName {String} имя таблицы
  @param where {Object} ключ-значение соответствия строки
  @param callback {Function}
  @param callback.error {String|null} возвращает строку с ошибкой или `null`
  @async
  ###
  find: (tableName, where, callback)=>

    keys = _.map(
      _.keys(where)
      (key, i)->
        return "#{key} = ?"
    ).join " AND "

    @client.query "SELECT * FROM ?? WHERE #{keys}", _.flatten([tableName, _.values(where)]), callback

module.exports = Mysql