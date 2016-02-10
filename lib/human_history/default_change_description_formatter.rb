module HumanHistory
  class DefaultChangeDescriptionFormatter
    attr_reader :attribute, :changes, :type

    def initialize(attribute, changes, type)
      @attribute = attribute
      @changes = changes
      @type = type
    end

    def change_description
      description = "the #{attribute_name} "
      description += "from #{format_change changes.first} " if include_from? changes.first
      description += "to #{format_change changes.last}"
    end

    def formattable?
      true
    end

    protected

    def attribute_name
      attribute.humanize(capitalize: false)
    end

    def format_change(change)
      requires_quotes?(change) ? "\"#{change}\"" : change
    end

    def include_from?(change)
      !change.nil? && (!change.respond_to?(:empty?) || !change.empty?)
    end

    def requires_quotes?(change)
      !change.is_a?(Integer) && !change.is_a?(TrueClass) && !change.is_a?(FalseClass)
    end

  end
end
