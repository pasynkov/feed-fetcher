
Handlebars = require "handlebars"
async = require "async"
_ = require "underscore"

###*
Главный контроллер проекта
@class MainController
@constructor
###
class MainController


  ###*
  Конструктор класса
  @method constructor
  ###
  constructor: (@context)->

    ###*

    Экземпляр класса Context запроса

    @property context
    @type {Context}
    ###

  ###*

  Возвращает главную страницу приложения

  @method index
  ###
  index: ->

    async.waterfall(
      [
        async.apply async.parallel, {
          index: async.apply core.readFileIfExists, "./src/index.hbr"
          menu: async.apply core.readFileIfExists, "./src/menu.hbr"
          list: async.apply core.readFileIfExists, "./src/list.hbr"
        }

        ({index, menu, settings, list}, taskCallback)->
          indexTemplate = Handlebars.compile index
          menuTemplate = Handlebars.compile(menu) indexActive: "active"

          taskCallback null, indexTemplate({menu: menuTemplate, content: list})
      ]
      @context.sendData
    )

  ###*

  Возвращает страницу настроек приложения

  @method settings
  ###
  settings: (incomingError)->

    async.waterfall(
      [
        async.apply async.parallel, {
          index: async.apply core.readFileIfExists, "./src/index.hbr"
          menu: async.apply core.readFileIfExists, "./src/menu.hbr"
          settings: async.apply core.readFileIfExists, "./src/settings.hbr"
        }

        ({index, menu, settings, list}, taskCallback)->
          indexTemplate = Handlebars.compile index
          menu = Handlebars.compile(menu) settingsActive: "active"
          settings = Handlebars.compile(settings) {
            cron: core.config.cron.runOn
            perPage: core.config.ui.perPage
            staticDir: core.config.fetcher.staticDir
          }

          taskCallback null, indexTemplate({menu, content: settings})
      ]
      (err, data)=>
        @context.sendData incomingError or err, data
    )

  ###*

  Возвращает список новостей

  @method getItems
  ###
  getItems: ->

    async.waterfall(
      [
        async.apply(
          core.getItems
          @context.requester.params.page*core.config.ui.perPage or 0
          core.config.ui.perPage
        )
        ({items, count}, taskCallback)=>

          taskCallback null, {
            result: {
              items
              pagination: do =>
                if count > core.config.ui.perPage
                  return _.map(
                    [0...Math.ceil(count/core.config.ui.perPage)]
                    (page)=>
                      return {
                        active: do=>
                          if +@context.requester.params.page is +page
                            return "active"
                          unless @context.requester.params.page
                            return if page is 0 then "active" else ""
                          return ""
                        value: page + 1
                        link: "javascript:getPage(#{page})"
                      }
                  )
                else
                  return false
            }
          }
      ]
      @context.sendData
    )

  ###*

  Возвращает одну новость по ID

  @method getItem
  ###
  getItem: ->
    core.getItem @context.requester.params.id, @context.sendData

  ###*

  Сохраняет настройки приложения

  @method saveSettings
  ###
  saveSettings: =>

    core.config.ui.perPage = @context.requester.body.perPage
    core.config.cron.runOn = @context.requester.body.cron
    core.config.fetcher.staticDir = @context.requester.body.staticDir

    core.saveSettings (err)=>
      @settings err




module.exports = MainController