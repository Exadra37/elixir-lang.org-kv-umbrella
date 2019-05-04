defmodule KV do
  use Application

  # This module is defined in the `mix.exs` as the one with the responsibility,
  # of starting the application.
  # Implements the `start/2` callback for the `Application` behaviour.
  def start(_type, _argd) do
    KV.Supervisor.start_link(name: KV.Supervisor)
  end
end
