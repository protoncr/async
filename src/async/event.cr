module Async
  class Event
    enum Status
      Unset
      Set
    end

    def initialize
      @status = Status::Unset
    end

    def wait
      Future.execute { wait_sync }
    end

    def wait(&block : -> U) forall U
      Future(U).execute { wait_sync; block.call }
    end

    def wait_sync
      loop do
        break if @status == Status::Set
        sleep 0.01
      end
    end

    def set
      @status = Status::Set
    end

    def clear
      @status = Status::Unset
    end

    def set?
      @status == Status::Set
    end
  end
end
