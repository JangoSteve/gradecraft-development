class HistoryFilter
  attr_reader :history

  def changesets
    history.map(&:changeset)
  end

  def initialize(history)
    @history = history
  end

  def exclude(options={})
    exclusions = options.keys

    @history = history.select do |history_item|
      result = exclusions.inject(true) do |select, exclusion|
        history_item.changeset[exclusion] != options[exclusion]
      end
      result &= !yield(history_item) if block_given?
      result
    end.delete_if { |history_item| empty_changeset?(history_item.changeset) }
    self
  end

  def include(options={})
    inclusions = options.keys

    @history = history.select do |history_item|
      result = inclusions.inject(true) do |select, inclusion|
        history_item.changeset[inclusion] == options[inclusion]
      end
      result &= yield(history_item) if block_given?
      result
    end.delete_if { |history_item| empty_changeset?(history_item.changeset) }
    self
  end

  def remove(options)
    name = options["name"]

    @history = history.select do |history_item|
      history_item.changeset.delete_if { |key, value| name == key } if name
    end.delete_if { |history_item| empty_changeset?(history_item.changeset) }
    self
  end

  def rename(options)
    object_key = options.keys.first
    object_value = options.values.first

    history.map(&:changeset).each do |changeset|
      object = changeset["object"]
      changeset["object"] = object_value if object == object_key
    end
    self
  end

  def empty_changeset?(set)
    set.values.none? { |value| value.is_a? Array }
  end
end
