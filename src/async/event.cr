module Async
  class Event
    enum Status
      Unset
      Set
    end

    def initialize
      @status = Status::Unset
      @channel = Channel(Status).new(1)
    end

    async def wait
      loop do
        if @channel.receive == Status::Set
          return
        end
      end
    end

    def set
      @channel.send(Status::Set)
    end

    def clear
      @channel.send(Status::Unset)
    end

    def set?
      @status == Status::Set
    end
  end
end
