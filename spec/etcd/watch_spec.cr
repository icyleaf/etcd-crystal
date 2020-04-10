require "../spec_helper"

describe "Etcd watch" do
  it "without index, returns the value at a particular index" do
    key = random_key(4)
    value1 = UUID.random.to_s
    value2 = UUID.random.to_s

    index1 = client.create(key, {:value => value1}).node.modified_index
    index2 = client.compare_and_swap(key, {:value => value2, :prevValue => value1}).node.modified_index

    client.watch(key, {:index => index1}).node.value.should eq(value1)
    client.watch(key, {:index => index2}).node.value.should eq(value2)
  end

  it "with index, waits and return when the key is updated" do
    key = random_key

    value = UUID.random.to_s
    channel = Channel(Etcd::Response).new

    spawn do
      channel.send(client.watch(key))
    end
    sleep 2
    client.set(key, {:value => value})

    response = channel.receive
    response.node.value.should eq(value)
  end

  it "with recrusive, waits and return when the key is updated" do
    key = random_key
    value = UUID.random.to_s
    client.set("#{key}/subkey", {:value => "initial_value"})

    channel = Channel(Etcd::Response).new

    spawn do
      channel.send(client.watch(key, {:recursive => true}, 3))
    end

    sleep 2
    client.set("#{key}/subkey", {:value => value})

    response = channel.receive
    response.node.value.should eq(value)
  end
end
