defmodule KVTest do
  use ExUnit.Case
  doctest KV

  test "application is started by the Supervisor" do
    :ok = KV.Registry.create(KV.Registry, "shopping")
    {result, _pid} = KV.Registry.lookup(KV.Registry, "shopping")
    assert result = :ok
  end
end
