# TODO: Docs
module Async
  def self.ensure_future(future)
    Future.execute { await future }
  end
end

macro async(method)
  {% args = method.args %}
  {% splat = method.splat_index || -1 %}

  {% args_str = args.map_with_index { |a, i| i == splat ? "*#{a}" : a.stringify }.join(", ") %}

  {% if method.double_splat %}
    {% if args.size > 0 %}
      {% args_str += ", " %}
    {% end %}
    {% args_str += "**#{method.double_splat}" %}
  {% end %}

  {% if method.block_arg %}
    {% if args.size > 0 %}
      {% args_str += ", " %}
    {% end %}
    {% args_str += "&#{method.block_arg}" %}
  {% end %}

  def __async_{{ method.name }}({{ args_str.id }})
    {{ method.body }}
  end

  {% if method.block_arg %}
    def {{ method.name }}(*args, **kwargs, {{ "&#{method.block_arg}".id }})
        Async::Future.execute { __async_{{ method.name }}(*args, **kwargs, {{ "&#{method.block_arg.name}".id }}) }
    end
  {% else %}
    def {{ method.name }}(*args, **kwargs)
      Async::Future.execute { __async_{{ method.name }}(*args, **kwargs) }
    end
  {% end %}
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

require "./async/*"
