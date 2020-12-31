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

### `async` / `await`

Async also includes the loved and hated `async` / `await`.

The `async` macro works by wrapping the body of your function in a `Future.execute` callback. This brings with it the draw back that you won't be able to use `return` inside of your functions, but `next` should work if you need to exit early and return a value.

`await` can be used on async methods and futures to wait for the return value. All it really does currently is call `.wait`.

## Contributing

1. Fork it (<https://github.com/protoncr/async/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Chris Watson](https://github.com/watzon) - creator and maintainer
