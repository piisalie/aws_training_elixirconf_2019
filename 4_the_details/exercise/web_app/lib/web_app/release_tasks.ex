defmodule WebApp.ReleaseTasks do
  @moduledoc ~S"""
  These functions are made available via the release artifact during deployment.
  """
  @start_apps [
    :crypto,
    :ssl,
    :postgrex,
    :ecto,
    :ecto_sql
  ]

  @repos Application.get_env(:web_app, :ecto_repos, [])

  def migrate() do
    if should_run_migrations() do
      start_services()
      run_migrations()
      stop_services()
    else
      IO.puts("Not the lowest IP - Nothing to do.")
    end
  end

  def ensure_db() do
    start_services()
    create_db()
    stop_services()
  end

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

  defp start_services do
    IO.puts("Starting dependencies..")
    Enum.each(@start_apps, &Application.ensure_all_started/1)
    IO.puts("Starting repos..")
    Enum.each(@repos, & &1.start_link(pool_size: 2))
  end

  defp stop_services do
    IO.puts("Success!")
    :init.stop()
  end

  defp run_migrations do
    Enum.each(@repos, &run_migrations_for/1)
  end

  defp run_migrations_for(repo) do
    app = Keyword.get(repo.config, :otp_app)
    IO.puts("Running migrations for #{app}")
    migrations_path = priv_path_for(repo, "migrations")
    Ecto.Migrator.run(repo, migrations_path, :up, all: true)
  end

  defp priv_path_for(repo, filename) do
    app = Keyword.get(repo.config, :otp_app)

    repo_underscore =
      repo
      |> Module.split()
      |> List.last()
      |> Macro.underscore()

    priv_dir = "#{:code.priv_dir(app)}"

    Path.join([priv_dir, repo_underscore, filename])
  end

  defp create_db do
    Enum.each(@repos, fn repo ->
      case repo.__adapter__.storage_up(repo.config) do
        :ok ->
          IO.puts("The database for #{inspect(repo)} has been created")

        {:error, :already_up} ->
          IO.puts("The database for #{inspect(repo)} has already been created")

        {:error, term} when is_binary(term) ->
          Mix.raise("The database for #{inspect(repo)} couldn't be created: #{term}")

        {:error, term} ->
          Mix.raise("The database for #{inspect(repo)} couldn't be created: #{inspect(term)}")
      end
    end)
  end

  defp should_run_migrations do
    System.cmd("find_peers", [])
    |> case do
      {peers, 0} ->
        lowest_ip =
          peers
          |> String.split("\n", trim: true)
          |> Enum.sort()
          |> hd

        System.get_env("INTERNAL_IP") == lowest_ip

      _ ->
        raise "Unable to discover peers!"
    end
  end
end
