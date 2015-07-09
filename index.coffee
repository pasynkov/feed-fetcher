Core = (require "./classes/core")

global.core = new Core

core.initialize (err)->

  if err
    return core.logger.error "Initialize failed with err: `#{err}`"
