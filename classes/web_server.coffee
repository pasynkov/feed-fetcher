
express = require "express"
bodyParser = require "body-parser"

Context = require "./context"
router = require "../config/router"

path = require "path"

###*
Веб-сервер. Простейший класс управления веб-сервером
@class WebServer
@constructor
###
class WebServer


  ###*
  Конструктор класса
  @method constructor
  ###
  constructor: ->

    ###*

    Веб-сервер `express`

    @property server
    @type {Object}
    ###
    @server = express()

    @server.use bodyParser.urlencoded(extended: true)

    ###*

    Конфиг веб-сервера

    @property config
    @type {Object}
    ###
    @config = core.config.webServer

    ###*

    Логгер

    @property logger
    @type {Object}
    ###
    @logger = core.createLogger(
      {
        name: "webServer"
        options:
          console:
            level: "info"
            colorize: "true"
            label: "WebServer"
      }
    )

    router.call @


  ###*

  Задает роут веб-серверу, с указанием ответственного контроллера и его метода

  @method addRoute
  @param method {String} метод запроса (POST, GET, PUT и др)
  @param route {String} роут
  @param controllerName {String} имя контроллера
  @param action {String} имя метода контроллера
  ###
  addRoute: (method, route, controllerName, action)->
    @server[method] route, (req, res)->
      Controller = require path.resolve ".", "controllers", controllerName
      context = new Context req, res, controllerName, action
      controller = new Controller context
      controller[action]()


  ###*

  Запускает веб-сервер

  @method start
  @param callback {Function}
  @param callback.error {String|null} возвращает строку с ошибкой или `null`
  @async
  ###
  start: (callback)=>
    @server.listen @config.port, =>
      @logger.info "Start listen port `#{@config.port}`"
      callback()



module.exports = WebServer