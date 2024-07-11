module Async
  class Future(T)
    enum State
      Idle
      Delayed
      Running
      Completed
      Canceled
    end

    getter state : State
    getter result : T?
    getter error : Exception?

    property name : String?
    property delay : Time::Span
    property callback : Proc(T)?

    @channel : Channel(Nil)
    @fiber : Fiber?

    def initialize(*, name : String? = nil, delay = 0, callback : Proc(T)?)
      @name = name
      @state = State::Idle
      @delay = delay.is_a?(Number) ? delay.seconds : delay
      @callback = callback
      @channel = Channel(Nil).new
    end

    def self.new(*args, **kwargs, &block : -> T)
      new(*args, **kwargs, callback: block)
    end

    def self.new(*args, **kwargs)
      new(*args, *kwargs, callback: nil)
    end

    def self.execute(*args, **kwargs, &block : -> T)
      new(*args, **kwargs, &block).execute
    end

    def self.await(*args, **kwargs, &block : -> T)
      self.execute(*args, **kwargs, &block).wait
    end

    def self.all(futures : Enumerable(Future(U)), ordered = false) forall U
      if ordered
        channels = Array.new(futures.size) { Channel(U?).new }

        futures.zip(channels).each do |f, c|
          spawn do
            if f.state <= State::Completed
              f.wait
            end

            c.send(f.result)
          end
        end

        channels.map { |c| c.receive }
      else
        channel = Channel(U?).new(futures.size)

        futures.each do |f|
          spawn do
            if f.state <= State::Completed
              f.wait
            end

            channel.send(f.result)
          end
        end

        Array(U?).new(futures.size) { channel.receive }
      end
    end

    def self.all(futures : Enumerable(Future(U)), ordered = false, &block : U? ->) forall U
      yield self.all(*futures, ordered, &block)
    end

    def self.all(*futures : Future(U), ordered = false) forall U
      self.all(futures, ordered)
    end

    def self.all(*futures : Future(U), ordered = false, &block : U? ->) forall U
      self.all(futures, ordered, &block)
    end

    def self.any(futures : Enumerable(Future(U))) forall U
      channel = Channel(U?).new(1)

      futures.each do |f|
        spawn do
          if f.state <= State::Completed
            f.wait
          end

          if f.completed?
            channel.send(f.result) if !channel.closed?
          end
        end
      end

      value = channel.receive
      value
    end

    def self.any(futures : Enumerable(Future(U)), &block : U ->) forall U
      yield self.any(*futures)
    end

    def self.any(*futures : Future(U), &block : U ->) forall U
      yield self.any(futures)
    end

    def self.any(*futures : Future(U)) forall U
      self.any(futures)
    end

    def self.race(futures : Enumerable(Future(U))) forall U
      channel = Channel(U?).new(1)

      futures.each do |f|
        spawn do
          if f.state <= State::Completed
            f.wait
          end

          channel.send(f.result) if !channel.closed?
        end
      end

      value = channel.receive
      value
    end

    def self.race(futures : Enumerable(Future(U)), &block : U ->) forall U
      yield self.race(*futures)
    end

    def self.race(*futures : Future(U), &block : U ->) forall U
      yield self.race(futures)
    end

    def self.race(*futures : Future(U)) forall U
      self.race(futures)
    end

    def success?
      completed? && !@error
    end

    def failure?
      completed? && @error
    end

    def canceled?
      @state == State::Canceled
    end

    def completed?
      @state == State::Completed
    end

    def running?
      @state == State::Running
    end

    def delayed?
      @state == State::Delayed
    end

    def idle?
      @state == State::Idle
    end

    def result=(value : T)
      @result = value
    end

    def error=(value : String | Exception)
      if value.is_a?(String)
        value = Exception.new(value)
      end
      @error = value
    end

    def execute
      if @state >= State::Delayed
        return self
      end

      @state = @delay.total_seconds > 0 ? State::Delayed : State::Running

      @fiber = spawn { run_compute }
      self
    end

    def wait : T?
      unless @channel.closed?
        @channel.receive
        @channel.close
      end
      @result
    end

    def wait! : T
      ret = wait

      if error = @error
        raise error
      end

      {% if T.nilable? %}
        ret
      {% else %}
        ret.not_nil!
      {% end %}
    end

    def cancel
      @channel.close
      if @state >= State::Completed
        false
      else
        @state = State::Canceled
        true
      end
    end

    private def run_compute
      callback = @callback

      if !callback
        @state = State::Completed
        self.error = "Tried to execute a future with no callback"
        return
      end

      if @state = State::Delayed
        sleep @delay
        return if @state == State::Canceled
        @state = State::Running
      end

      begin
        self.result = callback.call
        @state = State::Completed
        @channel.send(nil)
      rescue ex
        self.error = ex
        @channel.send(nil)
      end
    end
  end
end
