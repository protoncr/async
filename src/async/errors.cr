module Async
  class AsyncException < Exception; end

  class CancelledError < AsyncException; end

  class UncaughtException(T) < AsyncException
    getter future : Async::Future(T)
    getter exception : Exception

    def initialize(@future : Async::Future(T), @exception : Exception)
      message = String.build do |str|
        str << "in future"
        if name = @future.name
          str << " '#{name}'"
        end
        str << ":\n\n"
        exception.inspect_with_backtrace.split('\n').each do |ln|
          str.puts (" " * 4) + ln
        end
      end

      super(message)
    end
  end
end
