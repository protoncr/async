module Async
  class AsyncException < Exception; end

  class CancelledError < AsyncException; end

  class UncaughtException < AsyncException
    getter exception : Exception

    def initialize(@exception : Exception)
      super("Uncaught exception in future:\n#{exception.inspect_with_backtrace}")
    end
  end
end
