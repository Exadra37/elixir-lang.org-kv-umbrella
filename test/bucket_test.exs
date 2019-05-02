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

    test "deletes values by key", %{bucket: bucket} do
        assert KV.Bucket.get(bucket, "cereals") == nil

        KV.Bucket.put(bucket, "cereals", 2)
        assert KV.Bucket.get(bucket, "cereals") == 2

        KV.Bucket.delete(bucket, "cereals")
        assert KV.Bucket.get(bucket, "cereals") == nil
    end
end
