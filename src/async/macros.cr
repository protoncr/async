# Method prefix which creates 2 version of your method, a sync and asyc variant.
# The async variant will have the given method name, while the sync variant will
# be postfixed `_sync`.
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

  def {{ method.name }}_sync({{ args_str.id }})
    {{ method.body }}
  end

  {% if method.block_arg %}
    def {{ method.name }}(*args, **kwargs, {{ "&#{method.block_arg}".id }})
        Async::Future.execute { {{ method.name }}_sync(*args, **kwargs, {{ "&#{method.block_arg.name}".id }}) }
    end
  {% else %}
    def {{ method.name }}(*args, **kwargs)
      Async::Future.execute { {{ method.name }}_sync(*args, **kwargs) }
    end
  {% end %}
end

# Wait for a future to return. Raises `Async::UncaughtException` if an
# exception occurs within.
macro await(method)
  %future = {{ method }}

  unless %future.is_a?(Async::Future)
    raise "await can only be used on async methods"
  end

  begin
    %future.wait!
  rescue ex
    raise Async::UncaughtException.new(%future, ex)
  end
end
