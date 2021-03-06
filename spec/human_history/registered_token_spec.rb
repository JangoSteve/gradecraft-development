require "spec_helper"
require "./lib/human_history/actor_history_token"
require "./lib/human_history/registered_token"

describe HumanHistory::RegisteredToken do
  describe "#create" do
    subject { described_class.new HumanHistory::ActorHistoryToken, ->(key, value) { true } }

    it "creates an object of the registered type with a key and value" do
      result = subject.create(:key, :value, Object)
      expect(result).to be_kind_of HumanHistory::ActorHistoryToken
    end
  end
end
