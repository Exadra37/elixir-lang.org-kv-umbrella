defmodule KV.RegistryTest do
   use ExUnit.Case, async: true

    setup do
        # using start_supervised!/1 to start the process guarantees that ExUnit
        # shuts down the KV.Registry process before it starts a new one for the
        # next test, thus not leaking state between tests.
        registry = start_supervised!(KV.Registry)
        %{registry: registry}
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
        assert KV.Registry.lookup(registry, "shopping") == :error
    end
end
