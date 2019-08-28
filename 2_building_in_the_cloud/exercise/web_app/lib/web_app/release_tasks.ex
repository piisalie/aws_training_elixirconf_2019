defmodule WebApp.ReleaseTasks do
  def find_peers() do
    System.cmd("find_peers", [])
    |> case do
      {peers, 0} ->
        peers
        |> String.split("\n", trim: true)
        |> Enum.each(fn host -> Node.ping(:"web_app@#{host}") end)

      _ ->
        IO.puts("no hosts found")
    end
  end
end
