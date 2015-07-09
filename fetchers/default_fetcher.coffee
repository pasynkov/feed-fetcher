Fetcher = require "../classes/fetcher"

async = require "async"
_ = require "underscore"

###*
Фетчер по-умолчанию. Максимально просто получает и сохараняет материалы.
@class DefaultFetcher
@constructor
###
class DefaultFetcher extends Fetcher


  ###*
  Конструктор класса
  @method constructor
  ###
  constructor: (@name, @link)->

    ###*

    Наименование фетчера

    @property name
    @type {String}
    ###

    ###*

    Ссылка до источника

    @property link
    @type {String}
    ###

    ###*

    Логгер

    @property logger
    @type {Object}
    ###
    @logger = core.createLogger(
      name: "DefaultFetcher"
      options:
        console:
          level: "info"
          colorize: true
          label: "DefaultFetcher"
    )

  ###*

  Запрашивает у источника материалы и сохраняет их

  @method fetch
  @param callback {Function}
  @param callback.error {String|null} возвращает строку с ошибкой или `null`
  @async
  ###
  fetch: (callback)->

    @logger.info "Start fetch by `#{@name}` fetcher"

    async.waterfall(
      [
        @getItems

        (items, taskCallback)=>

          @logger.info "Received `#{items.length}` items by `#{@name}` fetcher"

          @storeItems items, taskCallback

        (items, taskCallback)=>

          added = _.compact items

          @logger.info "Successfully added #{added.length} items by `#{@name}` fetcher"

          taskCallback()

      ]
      callback
    )

  ###*

  Запрашивает и источника и возвращает материалы

  @method getItems
  @param callback {Function}
  @param callback.error {String|null} возвращает строку с ошибкой или `null`
  @param callback.items {Array} массив полученных материалов
  @async
  ###
  getItems: (callback)=>

    @logger.info "Get items for `#{@name}` fetcher"

    super @link, callback

  ###*

  Сохраняет материалы

  @method storeItems
  @param callback {Function}
  @param callback.error {String|null} возвращает строку с ошибкой или `null`
  @async
  ###
  storeItems: (items, callback)->

    @logger.info "Start store items for `#{@name}` fetcher"

    super _.map(
      items
      (item)->
        return {
        title: item.title
        content: item.summary
        created: new Date(item.pubdate)
        link: item.link
        author: item.author
        }
    ), callback

module.exports = DefaultFetcher