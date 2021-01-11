# TODO: Docs
module Async
  def self.ensure_future(future)
    Future.execute { await future }
  end
end

require "./async/errors"
require "./async/event"
require "./async/future"
require "./async/queue"
