Fetcher = require "../classes/fetcher"


class DefaultFetcher extends Fetcher


  constructor: (@name, @link)->

    @logger = core.createLogger(
      name: "DefaultFetcher"
      options:
        console:
          level: "info"
          colorize: true
          label: "DefaultFetcher"
    )

  fetch: (callback)->

    @logger.info "Start fetch by `#{@name}` fetcher"

    @getItems (err, items)=>
      @logger.info "fetched `#{items.length}` items"

  getItems: (callback)->
    super @link, callback

module.exports = DefaultFetcher