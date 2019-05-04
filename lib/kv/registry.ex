defmodule KV.Registry do
    use GenServer

    ## Client API

    @doc """
    Starts the registry.
    """
    def start_link(opts) do
        GenServer.start_link(__MODULE__, :ok, opts)
    end

    @doc """
    Looks up the bucket pid for `name` stored in `server`.

    Return `{:ok, pid}` if the bucket exists, `:error` otherwise.
    """
    def lookup(server, name) do
        GenServer.call(server, {:lookup, name})
    end

    @doc """
    Ensures there is a bucket associated with the given `name` in `server`.
    """
    def create(server, name) do

        # we use `cast` here for didactic purposes only, in a real production
        # application we should use `call`, because `cast` doesn't return a
        # reply, neither guarantees that the message was delivered, thus we are
        # just trusting that everything will work, and our bucket gets created.
        GenServer.cast(server, {:create, name})
    end


    ## Server Callbacks


    def init(:ok) do
        names = %{}
        refs = %{}
        {:ok, {names, refs}}
    end

    def handle_call({:lookup, name}, _from, state) do
        {names, _} = state
        {:reply, Map.fetch(names, name), state}
    end

    def handle_cast({:create, name}, {names, refs}) do
        if Map.has_key?(names, name) do
            {:noreply, {names, refs}}
        else

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
            names = Map.put(names, name, pid)

            {:noreply, {names, refs}}
        end
    end

    def handle_info({:DOWN, ref, :process, _pid, _reason}, {names, refs}) do
        {name, refs} = Map.pop(refs, ref)
        names = Map.delete(names, name)
        {:noreply, {names, refs}}
    end

    # catch all for messages we may receive, that we not care about, we only
    # want the above :DOWN
    def handle_info(_msg, state) do
        {:noreply, state}
    end
end
