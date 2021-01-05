# async

Async operations for Crystal, taking inspiration from Python's `asyncio.Future`, JavaScript Promises, and `async`/`await`.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     async:
       github: protoncr/async
   ```

2. Run `shards install`

## Usage

### Futures

Async contains futures, much like you'd find in Python's `asyncio`. Futures by default are not executed on creation, but are rather a building block to be used for other async operations.

```crystal
require "async"

# This is an empty future. Doesn't do much right now.
future = Async::Future(Int32).new
# => #<Async::Future(Int32):0x1016f2f50 ...>

future.state
# => Idle

# To put the future to use, we can give it a callback
future.callback = -> { sleep 5; 5 }

# The future still hasn't executed yet. To make it execute, we can
# call the `#execute` method
future.execute

# This will cause the callback to execute in the backround, allowing
# other tasks to happen concurrently. To wait for the execution to
# finish and retrieve the value, call `#wait`
future.wait
# => 5
```

Futures are made a bit more powerful when you use the `Future.execute` constructor:

```crystal
future = Async::Future.execute { sleep 5; 5 }
future.wait
# => 5
```

Futures also have built in error handling. If an error occurs while your callback is executing, the exception will be stored in the `error` property and `failure?` will be true. If you want to throw a possible exception during wait, you can do so with `wait!`.

```crystal
future = Async::Future.execute { sleep 5; 5_u8 + 251 }
future.wait!
# => Unhandled exception: Arithmetic overflow (OverflowError)
```

#### `.all` / `.any` / `.race`

Insipred by the JavaScript promise methods with the same names, the `.all`, `.any`, and `.race` methods can be used to wait for certain things to happen with your futures.

`.all` accepts _N_ futures and will wait for them all to finish before returning. The return value of `.all` is an `Array(T)` where `T` is the type(s) of the futures.

`.any` accepts _N_ futures and returns the value of the first future to complete successfully.

`.race` is similar to `.all`, but it returns the first time a future finishes, whether successful or not.

**Example:**
```crystal
fut1 = Async::Future.execute do
  loop do
    num = rand(1..99)
    sleep num
    puts "f1 " + num.to_s
    break if num == 69
  end
end

fut2 = Async::Future.execute do
  loop do
    num = rand(1..99)
    sleep num
    puts "f2 " + num.to_s
    break if num == 69
  end
end

Async::Future.all(fut1, fut2)
```

### `async` / `await`

Async also includes the loved and hated `async` / `await`.

The `async` macro basically works by wrapping the body of your function in a `Future` and executing that future immediately. Theoretically most functions should work just fine as async functions, but more complex function definitions are still untested. Most specifically functions with blocks.

`await` can be used on async methods and futures to wait for the return value. All it really does currently is call `.wait!`. If an exception is raised inside the future `await` will raise an `Async::UncaughtException` which contains the uncaught exception.

## Contributing

1. Fork it (<https://github.com/protoncr/async/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Chris Watson](https://github.com/watzon) - creator and maintainer
