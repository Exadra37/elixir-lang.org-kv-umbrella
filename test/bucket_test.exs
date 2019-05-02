defmodule KV.BucketTest do
    use ExUnit.Case, async: true

    setup do
        {:ok, bucket} = KV.Bucket.start_link([])
        %{bucket: bucket}
    end

    test "stores values by key", %{bucket: bucket} do
        # `bucket` is now the bucket from the setup block
        assert KV.Bucket.get(bucket, "milk") == nil

        KV.Bucket.put(bucket, "milk", 3)
        assert KV.Bucket.get(bucket, "milk") == 3
    end
end
