require "./async/*"

# TODO: Docs
module Async
  def self.ensure_future(future)
    Future.execute { await future }
  end
end

macro async(method)
  # FIXME: Currently only works with methods that don't have a `yield`. block.call
  # should work just fine.
  {% args = method.args %}
  {% splat = method.splat_index || -1 %}

  {% args_str = args.map_with_index { |a, i| i == splat ? "*" + a.stringify : a.stringify }.join(", ") %}
  {% if method.double_splat %}
    {% args_str += ", **" + method.double_splat.stringify %}
  {% end %}

  def {{ method.name }}({{ args_str.id }})
    Async::Future.execute { {{ method.body }} }
  end
end

macro await(method)
  %future = {{ method }}
  unless %future.is_a?(Async::Future)
    raise "await can only be used on async methods"
  end
  %future.wait
end

macro await!(method)
  %future = {{ method }}
  unless %future.is_a?(Async::Future)
    raise "await can only be used on async methods"
  end
  %future.wait!
end
