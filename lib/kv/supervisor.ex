defmodule KV.Supervisor do
    use Supervisor

    def start_link(opts) do
        Supervisor.start_link(__MODULE__, :ok, opts)
    end

    def init(:ok) do
        children = [
            {KV.Registry, name: KV.Registry}
        ]

        # the strategy `:one_for_one` means that only the child that stops or
        # crashes is restarted.
        Supervisor.init(children, strategy: :one_for_one)
    end
end
