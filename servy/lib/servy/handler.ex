defmodule Servy.Handler do
  require Logger

  def handle(request) do
    request
      |> parse
      |> rewrite_path
      #|> log
      |> route
      |> track
      # |> emojify
      |> format_response
  end

  def track(%{status: 404, path: path} = conv) do
    Logger.warn "Warning: #{path} is on the loose!"
    conv
  end

  def track(conv), do: conv

  def log(conv), do: IO.inspect conv

  def rewrite_path(%{path: "/wildlife"} = conv) do
    %{ conv | path: "/wildthings" }
  end

  def rewrite_path(%{path: path} = conv) do
    regex = ~r{\/(?<thing>\w+)\?id=(?<id>\d+)}
    captures = Regex.named_captures(regex, path)
    rewrite_path_captures(conv, captures)
  end

  def rewrite_path(conv), do: conv

  def rewrite_path_captures(conv, %{"thing" => thing, "id" => id}) do
  %{ conv | path: "/#{thing}/#{id}" }
end

def rewrite_path_captures(conv, nil), do: conv

  def parse(request) do
    [method, path, _] = request
      |> String.split("\n")
      |> List.first
      |> String.split(" ")

    %{
      method: method,
      path: path,
      resp_body: "",
      status: nil
    }
  end

  def route(%{method: "GET", path: "/wildthings"} = conv) do
    %{ conv | status: 200, resp_body: "Bears, Lions, Tigers" }
  end

  def route(%{method: "GET", path: "/bears"} = conv) do
    %{ conv | status: 200,resp_body: "Bears" }
  end

  def route(%{method: "GET", path: "/bears/" <> id} = conv) do
    %{ conv | status: 200, resp_body: "Bear #{id}" }
  end


  def route(%{method: "DELETE", path: "/bears/" <> _id} = conv) do
    %{ conv | status: 403, resp_body: "Deleting a bear is forbidden" }
  end

  def route(conv) do
    %{ conv | status: 404, resp_body: "No #{conv.path} here!" }
  end

  def format_response(conv) do
    # TODO: Use values in the map to create an HTTP response string:
    """
    HTTP/1.1 #{conv.status} #{status_reason(conv.status)}
    Content-Type: text/html
    Content-Length: #{byte_size(conv.resp_body)}

    #{conv.resp_body}
    """
  end

  def emojify(%{status: 200, resp_body: resp_body} = conv) do
    %{conv | resp_body: "🐻 " <> resp_body <> " 🐻"}
  end

  def emojify(conv), do: conv

  defp status_reason (code) do
    %{
      200 => "OK",
      201 => "Created",
      401 => "Unauthorized",
      403 => "Forbidden",
      404 => "Not Found",
      500 => "Internal Server Error"
    }[code]
  end
end

request1 = """
GET /wildthings HTTP/1.1
Host: example.com
User-Agent: ExampleBrowser/1.0
Accept: */*

"""

request2 = """
GET /bears/?id=1 HTTP/1.1
Host: example.com
User-Agent: ExampleBrowser/1.0
Accept: */*

"""

request3 = """
GET /something HTTP/1.1
Host: example.com
User-Agent: ExampleBrowser/1.0
Accept: */*

"""

request4 = """
DELETE /bears/1 HTTP/1.1
Host: example.com
User-Agent: ExampleBrowser/1.0
Accept: */*

"""

request5 = """
GET /wildlife HTTP/1.1
Host: example.com
User-Agent: ExampleBrowser/1.0
Accept: */*

"""

Servy.Handler.handle(request1)
  |> IO.inspect

Servy.Handler.handle(request2)
  |> IO.inspect

Servy.Handler.handle(request3)
  |> IO.inspect

Servy.Handler.handle(request4)
  |> IO.inspect

Servy.Handler.handle(request5)
  |> IO.inspect
