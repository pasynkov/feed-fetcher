
revalidator = require "revalidator"

###*
Валидатор материала
@class ItemValidator
@constructor
###
class ItemValidator

  ###*
  Конструктор класса
  @method constructor
  ###
  constructor: (@object)->


    ###*

    Объект валидации

    @property object
    @type {Object}
    ###


    ###*

    Схема валидации

    @property schema
    @type {Object}
    ###
    @schema = {
      type: "object"
      required: true
      properties:
        title: {
          description: "Title of news-item"
          type: "string"
          pattern: /[А-яA-z]/
          required: true
          maxLength: 255
          allowEmpty: false
        }
        content: {
          description: "Content of news-item"
          type: "string"
          required: true
          allowEmpty: false
        }
        author: {
          description: "Author of news-item"
          type: "string"
          required: true
          allowEmpty: false
          maxLength: 255
        }
        link: {
          description: "Link to news-item"
          type: "string"
          format: "url"
          required: true
          allowEmpty: false
          maxLength: 255
        }
        fetcher: {
          description: "Link to news-item"
          type: "string"
          required: true
          allowEmpty: false
          maxLength: 255
        }
        created: {
          descriptions: "Created date of news-item"
          type: "string"
          pattern: /^\d\d\d\d-(\d)?\d-(\d)?\d \d\d:\d\d:\d\d$/
          required: true
          allowEmpty: false
        }
    }

    @validate()

  ###*

  Валидирует объект по схеме и назначает свойства

  `@valid`, `@error` по результатам валидации

  @method validate
  ###
  validate: ->

    {@valid, @errors} = revalidator.validate @object, @schema



module.exports = ItemValidator
