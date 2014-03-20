require_relative "../proofs_init.rb"
require 'replay/test'

class ReplayTest
  include Replay::Publisher

  key :pkey

  events do
    SomeEvent(pid: Integer)
    UnhandledEvent(pid: Integer)
  end

  apply SomeEvent do |event|
    @event_count ||=0 
    @event_applied = event.pid
    @event_count += 1
  end

  def pkey
    1
  end
end

module ReplayTest::Proof
  def defines_events?
    self.class.const_defined?(:SomeEvent) && self.class.const_get(:SomeEvent).is_a?(Class)
  end
  def adds_convenience_method?
    respond_to? :SomeEvent
  end
  def applies_event?(event)
    apply(event)
    @event_applied == event.pid
  end

  def applies_events?(events)
    apply(events)
    @event_count == events.count
  end

  def throws_unhandled_event?(raise_it = true)
    begin
      apply(UnhandledEvent(pid: 123), raise_it)
    rescue Replay::UnhandledEventError => e
      true && raise_it
    rescue Exception
      !raise_it || false 
    end
  end

  def can_publish_events?
    event = SomeEvent(pid: 123)
    publish(event)
    @_events.detect{|e| e==event}
    #test_event_stream.published?('1', SomeEvent(pid:123))
  end
end

title "Publisher"

proof "Defines events given in the events block" do
  r = ReplayTest.new
  r.prove{ defines_events? }
end

proof "Adds a convenience method for an event constructor to the class" do
  r = ReplayTest.new
  r.prove{ adds_convenience_method? }
end

proof "Applies events singly" do
  r = ReplayTest.new
  r.prove{ applies_event? ReplayTest::SomeEvent.new(:pid => 123)}
end

proof "Applies events in ordered batches" do
  r = ReplayTest.new
  r.prove do applies_events?([
      ReplayTest::SomeEvent.new(:pid => 123), 
      ReplayTest::SomeEvent.new(:pid => 234), 
      ReplayTest::SomeEvent.new(:pid => 456)
    ])
  end
end

proof "Throws an UnhandledEventError for unhandled events" do
  r = ReplayTest.new
  r.prove{ throws_unhandled_event? }
end

proof "Ignores unhandled events if requested" do
  r = ReplayTest.new
  r.prove{ throws_unhandled_event? false}
end

proof "Can publish events to the indicated stream" do
  r = ReplayTest.new
  r.prove { can_publish_events? }
end

proof "Returns self from publish" do
  r = ReplayTest.new
  r.prove{ publish([]) == self}
end
