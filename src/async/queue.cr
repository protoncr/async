module Async
  # First in, first out (FIFO) queue based on Python's own `asyncio.Queue`.
  class Queue(T)
    include Enumerable(T)

    # Returns the set max size for the queue.
    getter max_size : Int32?

    # Initializes a new `Queue`.
    #
    # If `max_size` is less than or equal to zero, the queue size is infinite.
    # If it is an integer greater than 0, then await `#put` blocks when the queue
    # reaches `max_size` until an item is removed by `#get`.
    def initialize(@max_size : Int32? = nil)
      @buffer = Array(T).new
      @mutex = Mutex.new
    end

    # Returns true if the queue is empty.
    def empty?
      @buffer.empty?
    end

    # Returns true if there are `max_size` items in the queue.
    def full?
      max_size = @max_size
      max_size ? @buffer.size >= max_size : false
    end

    # Remove and return an item from the queue. If the queue is empty, wait until
    # an item is available.
    def get
      Future.execute { get_sync }
    end

    # :ditto:
    def get_sync
      loop do
        if @buffer.size > 0
          return @mutex.synchronize { @buffer.pop }
        end
      end
    end

    # Return an item if one is immediately available, else raise `QueueEmptyError`.
    def get!
      if @buffer.size > 0
        return @mutex.synchronize { @buffer.pop }
      else
        raise Async::QueueEmptyError.new
      end
    end

    # Put an item into the queue. If the queue is full, wait until a free slot
    # is available before adding the item.
    def put(item : T)
      Future.execute { put_sync(item) }
    end

    def put_sync(item : T)
      loop do
        if !max_size || size < max_size.not_nil!
          break @mutex.synchronize { @buffer.push(item) }
        end
      end
    end

    # Put an item into the queue without blocking. If no free slot is
    # immediately available, raise `QueueFullError`.
    def push!(item : T)
      if !max_size || size < max_size.not_nil!
        @mutex.synchronize { @buffer.push(item) }
      else
        raise Async::QueueFullError.new
      end
    end

    # Returns the number of items in the queue.
    def size
      @buffer.size
    end

    # Iterate over each item in the queue. See `Array#each`.
    def each(&block : T ->)
      @buffer.each { |i| block.call(i) }
    end
  end
end
