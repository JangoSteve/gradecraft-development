require 'resque-retry'
require 'resque/errors'

class EventLogger
  extend Resque::Plugins::Retry
  @queue = :eventlogger
  @retry_limit = 3
  @retry_delay = 60
  @start_message = "Starting EventLogger"
  @success_message = "Event was successfully created."
  @failure_message = "Event creation wasnot successful."

  def self.perform(event_type, data={})
    p @start_message
    event = Analytics::Event.create self.event_attrs(event_type, data)
    notify_event_outcome(event)
  end

  def self.notify_event_outcome(event)
    puts (event.valid? ? @success_message : @failure_message)
  end

  def self.event_attrs(event_type, data)
    { event_type: event_type, created_at: Time.now }.merge data
  end

  # allow sub-classes to inherit class-level instance variables
  def self.inherited(subclass)
    ["@retry_limit", "@retry_delay", "@start_message"].each do |ivar|
      subclass.instance_variable_set(ivar, instance_variable_get(ivar))
    end
  end
end
