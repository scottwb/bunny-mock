require 'spec_helper'
require 'bunny_mock'

describe "BunnyMock Integration Tests", :integration => true do
  it "should handle the basics of message passing" do
    # Basic one-to-one queue/exchange setup.
    bunny = BunnyMock.new
    queue = bunny.queue(
      "integration_queue",
      :durable     => true,
      :auto_delete => true,
      :exclusive   => false,
      :arguments   => {"x-ha-policy" => "all"}
    )
    exchange = bunny.exchange(
      "integration_exchange",
      :type        => :direct,
      :durable     => true,
      :auto_delete => true
    )
    queue.bind(exchange)

    # Basic assertions
    queue.messages.should be_empty
    exchange.queues.should have(1).queue
    exchange.should be_bound_to "integration_queue"
    queue.default_consumer.message_count.should == 0

    # Send some messages
    exchange.publish("Message 1")
    exchange.publish("Message 2")
    exchange.publish("Message 3")

    # Verify state of the queue
    queue.messages.should have(3).messages
    queue.messages.should == [
      "Message 1",
      "Message 2",
      "Message 3"
    ]

    # Here's what we expect to happen when we subscribe to this queue.
    handler = mock("target")
    handler.should_receive(:handle_message).with("Message 1").ordered
    handler.should_receive(:handle_message).with("Message 2").ordered
    handler.should_receive(:handle_message).with("Message 3").ordered

    # Read all those messages
    msg_count = 0
    queue.subscribe do |msg|
      handler.handle_message(msg[:payload])
      msg_count += 1
      queue.default_consumer.message_count.should == msg_count
    end
  end
end

describe BunnyMock do
  Given(:bunny) { BunnyMock.new }

  describe "#queue" do
    When(:queue) { bunny.queue("my_queue", :durable => true) }
    Then { queue.should be_a BunnyMock::Queue }
    Then { queue.name.should == "my_queue" }
    Then { queue.should be_durable }
  end

  describe "#exchange" do
    When(:exchange) { bunny.exchange("my_exch", :type => :direct) }
    Then { exchange.should be_a BunnyMock::Exchange }
    Then { exchange.name.should == "my_exch" }
    Then { exchange.type.should == :direct }
  end
end

describe BunnyMock::Consumer do
  describe "#message_count" do
    Given(:consumer) { BunnyMock::Consumer.new(5) }
    Then { consumer.message_count.should == 5 }
  end
end

describe BunnyMock::Queue do
  Given(:queue_name) { "my_test_queue" }
  Given(:queue_attrs) {
    {
      :durable     => true,
      :auto_delete => true,
      :exclusive   => false,
      :arguments   => {"x-ha-policy" => "all"}
    }
  }
  Given(:queue) { BunnyMock::Queue.new(queue_name, queue_attrs) }

  describe "#name" do
    Then { queue.name.should == queue_name }
  end

  describe "#attrs" do
    Then { queue.attrs.should == queue_attrs }
  end

  describe "#messages" do
    Then { queue.messages.should be_an Array }
    Then { queue.messages.should be_empty }
  end

  describe "#delivery_count" do
    Then { queue.delivery_count.should == 0 }
  end

  describe "#subscribe" do
    Given { queue.messages = ["Ehh", "What's up Doc?"] }
    Given(:handler) { mock("handler") }
    Given {
      handler.should_receive(:handle).with("Ehh").ordered
      handler.should_receive(:handle).with("What's up Doc?").ordered
    }
    When { queue.subscribe { |msg| handler.handle(msg[:payload]) } }
    Then { queue.messages.should be_empty }
    Then { queue.delivery_count.should == 2 }
    Then { verify_mocks_for_rspec }
  end

  describe "#bind" do
    Given(:exchange) { BunnyMock::Exchange.new("my_test_exchange",) }
    When { queue.bind(exchange) }
    Then { exchange.should be_bound_to "my_test_queue" }
  end

  describe "#default_consumer" do
    Given { queue.delivery_count = 5 }
    When(:consumer) { queue.default_consumer }
    Then { consumer.should be_a BunnyMock::Consumer }
    Then { consumer.message_count.should == 5 }
  end

  describe "attribute accessors" do
    Then { queue.durable.should be_true }
    Then { queue.should be_durable }
    Then { queue.auto_delete.should be_true }
    Then { queue.should be_auto_delete }
    Then { queue.exclusive.should == false }
    Then { queue.should_not be_exclusive }
    Then { queue.arguments.should == {"x-ha-policy" => "all"} }
  end
end

describe BunnyMock::Exchange do
  Given(:exchange_name) { "my_test_exchange" }
  Given(:exchange_attrs) {
    {
      :type        => :direct,
      :durable     => true,
      :auto_delete => true
    }
  }
  Given(:exchange) { BunnyMock::Exchange.new(exchange_name, exchange_attrs) }

  describe "#name" do
    Then { exchange.name.should == exchange_name }
  end

  describe "#attrs" do
    Then { exchange.attrs.should == exchange_attrs }
  end

  describe "#queues" do
    context "when the exchange is not bound to any queues" do
      Then { exchange.queues.should be_an Array }
      Then { exchange.queues.should be_empty }
    end

    context "when the exchange is bound to a queue" do
      Given(:queue) { BunnyMock::Queue.new("a_queue") }
      Given { queue.bind(exchange) }
      Then { exchange.queues.should have(1).queue }
      Then { exchange.queues.first.should == queue }
    end
  end

  describe "#bound_to?" do
    Given(:queue) { BunnyMock::Queue.new("a_queue") }
    Given { queue.bind(exchange) }
    Then { exchange.should be_bound_to("a_queue") }
    Then { exchange.should_not be_bound_to("another_queue") }
  end

  describe "#publish" do
    Given(:queue1) { BunnyMock::Queue.new("queue1") }
    Given(:queue2) { BunnyMock::Queue.new("queue2") }
    Given { queue1.bind(exchange) }
    Given { queue2.bind(exchange) }
    When { exchange.publish("hello") }
    Then { queue1.messages.should == ["hello"] }
    Then { queue2.messages.should == ["hello"] }
  end

  describe "attribute accessors" do
    Then { exchange.type.should == :direct }
    Then { exchange.durable.should be_true }
    Then { exchange.should be_durable }
    Then { exchange.auto_delete.should be_true }
    Then { exchange.should be_auto_delete }
  end
end
