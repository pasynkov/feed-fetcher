
request = require "request"
FeedParser = require "feedparser"
async = require "async"
moment = require "moment"
_ = require "underscore"

fs = require "fs"
path = require "path"
crypto = require "crypto"

ItemValidator = require "../schemas/item"

DEFAULT_STATIC_DIR = "content"


###*
Класс-фетчер. Родительский класс для остыльных фетчеров. Умеет доставать и сохранять новости
@class Fetcher
@constructor
###
class Fetcher

  ###*
  Конструктор класса
  @method constructor
  ###
  constructor: ->


  ###*

  Возвращает массив распарсенных объектов RSS/ATOM ленты по входящей ссылка

  @method getItems
  @param link {String} входящяя ссылка
  @param callback {Function}
  @param callback.error {String|null} возвращает строку с ошибкой или `null`
  @param callback.result {Array} массив объектов новостей
  @async
  ###
  getItems: (link, callback)=>

    async.waterfall(
      [
        async.apply @getRequesterByLink, link

        @getItemsFromRequester

      ]
      callback
    )

  ###*

  Создает объект `request`-модуля с GET-запросом по входящей ссылке (для дальнейшего `pipe`).

  Если нет ошибки и HTTP-статус 200 - вернет этот объект, в ином случае - ответит ошибкой

  @method getRequesterByLink
  @param link {String} ссылка для GET-запроса
  @param callback {Function}
  @param callback.error {String|null} возвращает строку с ошибкой или `null`
  @param callback.result {Object} объект requester
  @async
  ###
  getRequesterByLink: (link, callback)=>

    request link
    .on "error", (err)->
      callback err

    .on "response", (response)->
      unless response.statusCode is 200
        return callback "Bad response"

      callback null, @

  ###*

  С помощью модуля `feedparser` распарсивает ленту из входящего `requester` (результирующий объект
  метода `getRequesterByLink`) и возвращает массив полученных материалов

  @method getItemsFromRequester
  @param requester {Object} объект GET-запроса `requester`'a
  @param callback {Function}
  @param callback.error {String|null} возвращает строку с ошибкой или `null`
  @param callback.result {Array} результирующий массив материалов
  @async
  ###
  getItemsFromRequester: (requester, callback)=>

    items = []

    feedParser = new FeedParser

    requester.pipe feedParser

    feedParser
    .on "error", (err)->

      callback err

    .on "readable", ->

      while item = @read()
        items.push item

    .on "end", ->

      callback null, items

  ###*

  Валидирует и сохраняет входящие новости в доступное хранилище

  @method storeItems
  @param items {Array} массив новостей
  @param callback {Function}
  @param callback.error {String|null} возвращает строку с ошибкой или `null`
  @async
  ###
  storeItems: (items, callback)=>

    items = @validateItems items

    unless items.length
      callback "Store failed. All items are not valid."

    if core.mysql.connected()

      @logger.info "Start store to mysql `#{items.length}`"

      @storeItemsToMysql items, callback

    else
      @logger.info "Start store to static files `#{items.length}`"

      @storeItemsToStatic items, callback

  ###*

  Сохраняет входящие новости в mysql

  @method storeItemsToMysql
  @param items {Array} массив новостей
  @param callback {Function}
  @param callback.error {String|null} возвращает строку с ошибкой или `null`
  @async
  ###
  storeItemsToMysql: (items, callback)=>

    async.map(
      items
      (item, done)=>
        async.waterfall(
          [
            async.apply core.mysql.find, "items", _.pick(item, ["title", "link", "fetcher"])
            ([rows] ..., taskCallback)=>
              if rows.length
                @logger.info "item `#{item.title}` of fetcher `#{item.fetcher}` already added"
                taskCallback()
              else
                core.mysql.insertRows "items", [item], taskCallback
          ]
          done
        )
      callback
    )

  ###*

  Сохраняет входящие новости в статичных файлах

  @method storeItemsToStatic
  @param items {Array} массив новостей
  @param callback {Function}
  @param callback.error {String|null} возвращает строку с ошибкой или `null`
  @async
  ###
  storeItemsToStatic: (items, callback)=>

    staticPath = path.join(__dirname, "..", core.config.fetcher.staticDir or DEFAULT_STATIC_DIR)

    async.waterfall(
      [
        async.apply core.checkDirectory, staticPath
        async.apply fs.readdir, staticPath
        (files, taskCallback)=>

          async.map(
            items
            (item, done)=>
              fileName = crypto.createHash("sha256")
              .update(item.title + item.link + item.fetcher)
              .digest("hex") + ".json"

              filePath = path.join(staticPath, fileName)

              fs.exists filePath, (exists)=>
                if exists
                  @logger.info "item `#{item.title}` of fetcher `#{item.fetcher}` already added"
                  done()
                else
                  fs.writeFile filePath, JSON.stringify(item, " ", " "), encoding: "utf8", (err)->
                    done err, item

            taskCallback
          )
      ]
      callback
    )

  ###*

  Валидирует входящие новости, возвращает только те, что прошли валидацию

  @method validateItems
  @param items {Array} массив новостей
  @return items {Array} массив валидных записей
  ###
  validateItems: (items)->

    return _.compact _.map(
      items
      (item)=>
        item.created = moment(item.created).format("YYYY-MM-DD HH:mm:ss")
        item.updated = moment().format("YYYY-MM-DD HH:mm:ss")
        item.added = moment().format("YYYY-MM-DD HH:mm:ss")
        item.fetcher = @name

        validator = new ItemValidator item

        if validator.valid
          return item
        else

          @logger.warn "Item isnt valid: `#{JSON.stringify validator.errors}`"

          return false
    )

module.exports = Fetcher