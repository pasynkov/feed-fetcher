class Scheduler

  constructor: ->

    @logger = core.createLogger(
      name: "scheduler"
      options:
        console:
          level: "info"
          colorize: true
          label: "Scheduler"
    )

  invoke: (callback)->

    core.fetchFeeds callback

module.exports = Scheduler