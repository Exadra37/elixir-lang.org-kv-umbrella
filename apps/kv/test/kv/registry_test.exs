defmodule KV.RegistryTest do
   use ExUnit.Case, async: true

    setup context do
        # using start_supervised!/1 to start the process guarantees that ExUnit
        # shuts down the KV.Registry process before it starts a new one for the
        # next test, thus not leaking state between tests.
        _ = start_supervised!({KV.Registry, name: context.test})
        %{registry: context.test}
    end

    test "spawns buckets", %{registry: registry} do
        assert KV.Registry.lookup(registry, "shopping") == :error

        KV.Registry.create(registry, "shopping")
        assert {:ok, bucket} = KV.Registry.lookup(registry, "shopping")

        KV.Bucket.put(bucket, "milk", 1)
        assert KV.Bucket.get(bucket, "milk") == 1
    end

    test "removes buckets on exit", %{registry: registry} do
        KV.Registry.create(registry, "shopping")
        {:ok, bucket} = KV.Registry.lookup(registry, "shopping")
        Agent.stop(bucket)

        # Do a call to ensure the registry processed the DOWN message
        # This works because messages are processed in order they arrive, thus
        # when this message to create the bogus bucket returns, it means that
        # the DOWN message is already processed.
        # This is necessary to avoid a race condition where the lookup call may
        # be processed before the DOWN message.
        # @link https://elixir-lang.org/getting-started/mix-otp/ets.html#race-conditions
        _ = KV.Registry.create(registry, "bogus")
        assert KV.Registry.lookup(registry, "shopping") == :error
    end

    test "removes bucket on crash", %{registry: registry} do
        KV.Registry.create(registry, "shopping")
        {:ok, bucket} = KV.Registry.lookup(registry, "shopping")

        # Stop the bucket with non-normal reason
        Agent.stop(bucket, :shutdown)

        # Do a call to ensure the registry processed the DOWN message
        _ = KV.Registry.create(registry, "bogus")
        assert KV.Registry.lookup(registry, "shopping") == :error
    end

    test "bucket can crash at any time", %{registry: registry} do
        KV.Registry.create(registry, "shopping")
        {:ok, bucket} = KV.Registry.lookup(registry, "shopping")

        # Simulate a bucket crash by explicitly and synchronously shutting it down
        Agent.stop(bucket, :shutdown)

        catch_exit KV.Bucket.put(bucket, "milk", 3)
    end
end
