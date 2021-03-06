require 'test_helper'
class TypedEvent

end
class Observer
  def self.published(stream, event)
    @typed=true
  end

  def self.typed_received?
    @typed
  end
end

describe Replay::Router::DefaultRouter do
  before do
    @router = Replay::Router::DefaultRouter.instance
  end
  describe "adding observers" do
    it "tracks the observing object" do
      @router.add_observer(Observer)
      @router.must_be :observed_by?, Observer
    end
  end
  describe "event publishing" do
    it "tells the observing object about events being published" do
      @router.add_observer(Observer)
      @router.published("123", TypedEvent.new)
      assert Observer.typed_received?, "Did not receive notification of event"
    end
  end
end

