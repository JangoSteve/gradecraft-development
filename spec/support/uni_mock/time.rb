module UniMock
  module StubTime
    def stub_now(parsable_date)
      allow(Time).to receive(:now) { Date.parse(parsable_date).to_time }
    end
  end
end
