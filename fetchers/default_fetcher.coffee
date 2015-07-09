Fetcher = require "../classes/fetcher"

async = require "async"
_ = require "underscore"

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

  getItems: (callback)=>

    @logger.info "Get items for `#{@name}` fetcher"

    super @link, callback

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