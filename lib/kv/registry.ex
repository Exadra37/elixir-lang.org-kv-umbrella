defmodule KV.Registry do
    use GenServer

    # For production use is best to use the Elixir official Registry module:
    # @link https://hexdocs.pm/elixir/Registry.html

    ## Client API

    @doc """
    Starts the registry with the given options.

    `:name` is always required.
    """
    def start_link(opts) do
        server = Keyword.fetch!(opts, :name)
        GenServer.start_link(__MODULE__, server, opts)
    end

    @doc """
    Looks up the bucket pid for `name` stored in `server`.

    Return `{:ok, pid}` if the bucket exists, `:error` otherwise.
    """
    def lookup(server, name) do
        case :ets.lookup(server, name) do
            [{^name, pid}] -> {:ok, pid}
            [] -> :error
        end
    end

    @doc """
    Ensures there is a bucket associated with the given `name` in `server`.
    """
    def create(server, name) do
        GenServer.call(server, {:create, name})
    end


    ## Server Callbacks


    def init(table) do
        names = :ets.new(table, [:named_table, read_concurrency: true])
        refs = %{}
        {:ok, {names, refs}}
    end

    def handle_call({:create, name}, _from, {names, refs}) do
        case lookup(names, name) do
            {:ok, pid} ->
                {:reply, pid, {names, refs}}

            :error ->

                # The previous normal Supervisor we had here starting the Bucket,
                # would link the Registry with the Bucket process, thus if the
                # Bucket was stopped or crashed the Registry would die to.
                #
                # So we don't want crash the `KV.Registry` each time a `KV.Bucket`
                # crashes or stop, thus we need to use a Dynamic Supervisor, instead
                # of a normal Supervisor.
                {:ok, pid} = DynamicSupervisor.start_child(KV.BucketSupervisor, KV.Bucket)

                # we need to monitor the Bucket process in order to be able to
                # remove it later when a Bucket stop or crashes.
                ref = Process.monitor(pid)
                refs = Map.put(refs, ref, name)
                :ets.insert(names, {name, pid})
                {:reply, pid, {names, refs}}
        end
    end

    def handle_info({:DOWN, ref, :process, _pid, _reason}, {names, refs}) do
        {name, refs} = Map.pop(refs, ref)
        :ets.delete(names, name)
        {:noreply, {names, refs}}
    end

    # catch all for messages we may receive, that we not care about, we only
    # want the above :DOWN
    def handle_info(_msg, state) do
        {:noreply, state}
    end
end
