

###*
Скрипт крон-задания фетчинга
@class Scheduler
@constructor
###
class Scheduler

  ###*
  Конструктор класса
  @method constructor
  ###
  constructor: ->

    ###*

    Логгер

    @property logger
    @type {Object}
    ###
    @logger = core.createLogger(
      name: "scheduler"
      options:
        console:
          level: "info"
          colorize: true
          label: "Scheduler"
    )

  ###*

  Непосредственно выполняет фетчинг

  @method invoke
  @param callback {Function}
  @param callback.error {String|null} возвращает строку с ошибкой или `null`
  @async
  ###
  invoke: (callback)->

    core.fetchFeeds callback

module.exports = Scheduler