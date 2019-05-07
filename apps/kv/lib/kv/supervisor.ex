defmodule KV.Supervisor do
    use Supervisor

    def start_link(opts) do
        Supervisor.start_link(__MODULE__, :ok, opts)
    end

    def init(:ok) do

        # The children order is important.
        # We want the Bucket to start before the Registry, because the Registry
        # may try to call the Bucket.
        children = [

            # The strategy `:one_for_one` means that only the child that stops
            # or crashes is restarted.
            {DynamicSupervisor, name: KV.BucketSupervisor, strategy: :one_for_one},
            {KV.Registry, name: KV.Registry},
        ]

        # The strategy `one_for_all` means that if one of the children dies, all
        # children must be restarted.
        Supervisor.init(children, strategy: :one_for_all)
    end
end
