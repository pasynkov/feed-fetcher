
_ = require "underscore"


###*
Класс контекста. Содержит упрощенные методы обработки запросов и ответов веб-сервера.
  Инициализируется при HTTP-запросах и отправляется в контроллер
@class Context
@constructor
###
class Context

  ###*
  Конструктор класса
  @method constructor
  ###
  constructor: (@requester, @responser, @controllerName, @action)->

    ###*

    Объект `request` модуля `express`

    @property requester
    @type {Object}
    ###

    ###*

    Объект `response` модуля `express`

    @property responser
    @type {Object}
    ###

    ###*

    Имя контроллера на который уходит запрос

    @property controllerName
    @type {String}
    ###

    ###*

    Имя метода на который уходит запрос

    @property action
    @type {String}
    ###

    ###*

    Логгер класса

    @property logger
    @type {Object}
    ###


    @logger = core.createLogger(
      {
        name: "context"
        options:
          console:
            level: "info"
            colorize: "true"
            label: "Context"
      }
    )


    @logger.info "incoming request to `#{@requester.url}`. Run controller `#{@controllerName}` with action `#{@action}`"

  ###*

  Отправляет данные на клиент. В случае наличия ошибки - обрабатывает ее.

  @method sendData
  @param err {String|null} ошибка выполнения роута контроллера
  @param data {Object|String} HTML или объект для выдачи на клиент
  ###
  sendData: (err, data)=>
    if err
      @responser.status 404

      if _.isObject(data)
        data = {
          error: err
        }

      @logger.error err

    @responser.send data

module.exports = Context