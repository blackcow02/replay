require 'test_helper'

class ObservedEvent
end

class UnobservedEvent
end

class ObserverTest
  include Replay::Observer
  observe ObservedEvent do |stream, event|
    @observed = true
  end

  def self.observed?
    @observed
  end

  def self.reset
    @observed=false
  end
end

class NonstandardRouter
  include Singleton
  include Replay::Router
end

class RoutedObserverTest
  include Replay::Observer
  router NonstandardRouter.instance

  observe ObservedEvent do |e|
  end
end

describe Replay::Observer do
  before do
    ObserverTest.reset
  end
  it "calls the observer block for observed events" do
    ObserverTest.published('123', ObservedEvent.new)
    ObserverTest.must_be :observed?
  end

  it "does not notify of unobserved events" do
    ObserverTest.published('123', UnobservedEvent.new)
    ObserverTest.wont_be :observed?
  end

  it "links to DefaultRouter by default" do
    Replay::Router::DefaultRouter.instance.must_be :observed_by?,ObserverTest
  end

  it "links to a substitute router when instructed" do
    NonstandardRouter.instance.must_be :observed_by?, RoutedObserverTest
  end
end
