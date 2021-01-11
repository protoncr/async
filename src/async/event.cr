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

    def wait
      Future.execute { sync_wait }
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

    private def sync_wait
      loop do
        if @channel.receive == Status::Set
          return
        end
      end
    end
  end
end
