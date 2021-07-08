class AppServer < Lucky::BaseAppServer
  # Learn about middleware with HTTP::Handlers:
  # https://luckyframework.org/guides/http-and-routing/http-handlers
  class WsHolder
    class_property holder : Hash(String, HTTP::WebSocket) = Hash(String, HTTP::WebSocket).new
    class_property activity : Hash(String, Time) = Hash(String, Time).new

    def self.send_by(key_wo_prefix : String)
      if ws = holder[routed_key(key_wo_prefix)]?
        if !ws.closed?
          yield ws
        end
      end
    end

    def self.add(key : String, ws : HTTP::WebSocket)
      puts "holder << add: #{key}"
      holder[key] = ws
      puts "holder size: #{holder.size}"
    end

    def self.remove(key : String)
      puts "holder >> remove: #{key}, last_seen_at: #{last_seen_at(key)}"
      holder.delete(key)
      puts "holder size: #{holder.size}"
    end

    def self.last_seen_at(key : String) : Time?
      activity[key]
    end

    def self.set_seen_at(key : String, time : Time) : Time
      puts "client:#{key} is alive"
      activity[key] = time
    end

    private def self.routed_key(key_wo_prefix : String) : String
      "/#{key_wo_prefix}"
    end
  end

  def middleware : Array(HTTP::Handler)
    [
      Lucky::ForceSSLHandler.new,
      Lucky::HttpMethodOverrideHandler.new,
      Lucky::LogHandler.new,
      Lucky::ErrorHandler.new(action: Errors::Show),
      Lucky::RemoteIpHandler.new,
      HTTP::WebSocketHandler.new do |ws, ctx|
        WsHolder.add(ctx.request.path, ws)
        ws.on_ping { ws.pong(ctx.request.path) }
        ws.on_close {
          WsHolder.remove(ctx.request.path)
        }
        ws.on_message do |message|
          ws.send(
            # message started from '*' will be ignored on client
            "***#{WsHolder.set_seen_at(ctx.request.path, Time.local).nanosecond}\n"
          )
        end
      end,
      Lucky::RouteHandler.new,
      Lucky::StaticCompressionHandler.new("./public", file_ext: "gz", content_encoding: "gzip"),
      Lucky::StaticFileHandler.new("./public", fallthrough: false, directory_listing: false),
      Lucky::RouteNotFoundHandler.new,
    ] of HTTP::Handler
  end

  def protocol
    "http"
  end

  def listen
    # Learn about bind_tcp: https://tinyurl.com/bind-tcp-docs
    server.bind_tcp(host, port, reuse_port: false)
    server.listen
  end
end
