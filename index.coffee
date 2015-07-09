Core = (require "./classes/core")

global.core = new Core

core.logger.info "Start application"

core.initialize (err)->

  if err
    return core.logger.error "Initialize failed with err: `#{err}`"
