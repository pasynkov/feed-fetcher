
request = require "request"
FeedParser = require "feedparser"
async = require "async"
moment = require "moment"
_ = require "underscore"

ItemValidator = require "../schemas/item"

class Fetcher

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


  storeItems: (items, callback)=>

    unless items.length
      return callback()

    items = _.compact _.map(
      items
      (item)=>
        item.created = moment(item.created).format("YYYY-mm-dd HH:ii:ss")
        item.updated = moment().format("YYYY-mm-dd HH:ii:ss")
        item.added = moment().format("YYYY-mm-dd HH:ii:ss")
        item.fetcher = @name

        validator = new ItemValidator item

        if validator.valid
          return item
        else

          @logger.warn "Item isnt valid: `#{JSON.stringify validator.errors}`"

          return false
    )

    unless items.length
      callback "Store failed. All items are not valid."

    if core.mysql.connected()

      @logger.info "Start store to mysql `#{items.length}`"

      core.mysql.insertRows "items", items, callback

    else
      @logger.info "Start store to static files `#{items.length}`"

      callback "Not connected"

module.exports = Fetcher