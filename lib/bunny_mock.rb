class BunnyMock

  def start
    :connected
  end

  def qos
    :qos_ok
  end

  def stop
    nil
  end

  def queue(*attrs)
    BunnyMock::Queue.new(*attrs)
  end

  def exchange(*attrs)
    BunnyMock::Exchange.new(*attrs)
  end

  class Consumer
    attr_accessor :message_count
    def initialize(c)
      self.message_count = c
    end
  end

  class Queue
    attr_accessor :name, :attrs, :messages, :delivery_count
    def initialize(name, attrs = {})
      self.name           = name
      self.attrs          = attrs.dup
      self.messages       = []
      self.delivery_count = 0
    end

    def bind(exchange)
      exchange.queues << self
    end

    # Note that this doesn't block waiting for messages like the real world.
    def subscribe(*args, &block)
      while message = messages.shift
        self.delivery_count += 1
        yield({:payload => message})
      end
    end

    def default_consumer
      BunnyMock::Consumer.new(self.delivery_count)
    end

    # NOTE: This is NOT a method that is supported on real Bunny queues.
    #       This is a custom method to get us a deep copy of
    #       all the messages currently in the queue. This is provided
    #       to aid in testing a system where it is not practical for the
    #       test to subscribe to the queue and read the messages, but we
    #       need to verify that certain messages have been published.
    def snapshot_messages
      Marshal.load(Marshal.dump(messages))
    end

    def method_missing(method, *args)
      method_name  = method.to_s
      is_predicate = false
      if method_name =~ /^(.*)\?$/
        key           = $1.to_sym
        is_predicate = true
      else
        key = method.to_sym
      end

      if attrs.has_key? key
        value = attrs[key]
        is_predicate ? !!value : value
      else
        super
      end
    end
  end

  class Exchange
    attr_accessor :name, :attrs, :queues
    def initialize(name, attrs = {})
      self.name   = name
      self.attrs  = attrs.dup
      self.queues = []
    end

    def publish(msg, msg_attrs = {})
      queues.each { |q| q.messages << msg }
    end

    def bound_to?(queue_name)
      queues.any?{|q| q.name == queue_name}
    end

    def method_missing(method, *args)
      method_name  = method.to_s
      is_predicate = false
      if method_name =~ /^(.*)\?$/
        key           = $1.to_sym
        is_predicate = true
      else
        key = method.to_sym
      end

      if attrs.has_key? key
        value = attrs[key]
        is_predicate ? !!value : value
      else
        super
      end
    end
  end

end
