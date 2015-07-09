module.exports = ->

  @addRoute "get", "/", "main", "index"

  @addRoute "get", "/settings", "main", "settings"
  @addRoute "post", "/settings", "main", "saveSettings"

  @addRoute "get", "/items", "main", "getItems"
  @addRoute "get", "/items/:page", "main", "getItems"

  @addRoute "get", "/item/:id", "main", "getItem"