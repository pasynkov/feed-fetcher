
revalidator = require "revalidator"

class ItemValidator

  constructor: (@object)->

    @schema = {
      title: {
        description: "Title of news-item"
        type: "string"
        pattern: "/[А-яA-z]/"
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
        format: "date"
        required: true
        allowEmpty: false
      }
    }

    @validate()

  validate: ->

    {@valid, @errors} = revalidator.validate @object, @schema



module.exports = ItemValidator
