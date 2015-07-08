Core = (require "./classes/core")

global.core = new Core

core.initialize (err)->

  if err
    core.logger.error "Initialize failed with err: `#{err}`"
    process.exit 1
  else
    core.logger.info "Initialized successfully"