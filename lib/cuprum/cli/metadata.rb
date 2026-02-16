# frozen_string_literal: true

require 'sleeping_king_studios/tools/toolbox/mixin'

require 'cuprum/cli'

module Cuprum::Cli
  # Class methods for describing commands.
  module Metadata
    extend SleepingKingStudios::Tools::Toolbox::Mixin

    # Format used to validate command names.
    FULL_NAME_FORMAT = /\A[a-z_]+(:[a-z_]+)*\z/

    UNDEFINED = SleepingKingStudios::Tools::UNDEFINED
    private_constant :UNDEFINED

    # Class methods to extend when including Metadata.
    module ClassMethods
      # @overload description
      #   @return [String] the description for the command.
      #
      # @overload description(value)
      #   Sets the description for the command.
      #
      #   @param value [String] the description to set.
      #
      #   @return [String] the set description.
      def description(value = UNDEFINED)
        return @description if value == UNDEFINED

        tools.assertions.validate_name(value, as: 'description')

        @description = value
      end

      # @overload full_description
      #   @return [String] the full description for the command.
      #
      # @overload full_description(value)
      #   Sets the full description for the command.
      #
      #   @param value [String] the full description to set.
      #
      #   @return [String] the set full description.
      def full_description(value = UNDEFINED)
        return @full_description || description if value == UNDEFINED

        tools.assertions.validate_name(value, as: 'full_description')

        @full_description = value
      end

      # @overload full_name
      #   Returns the name of the command, used when calling from a CLI.
      #
      #   Unless another value is set, defaults to the class name of the command
      #   with the following format:
      #
      #   - Removes the "Commands" namespace and any prior namespace, if any.
      #   - Removes a "Command" suffix, if any.
      #   - Converts each remaining segment to snake_case and joins with ":".
      #
      #   @return [String] the scoped name for the command.
      #
      # @overload full_name(value)
      #   Sets the full name for the command.
      #
      #   The full name must be in snake_case format joined by ":".
      #
      #   @param value [String] the full name to set.
      #
      #   @return [String] the set full name.
      def full_name(value = UNDEFINED)
        return @full_name ||= default_name if value == UNDEFINED

        tools.assertions.validate_name(value, as: 'full_name')
        tools.assertions.validate_matches(
          value,
          as:       'full_name',
          expected: FULL_NAME_FORMAT,
          message:  invalid_full_name_format_message
        )

        @full_name = value
      end

      # @return [String] the short name for the command.
      def short_name = full_name&.split(':')&.last

      private

      def default_name
        return if name.nil?

        name
          .split('Commands::')
          .last
          .sub(/Command\z/, '')
          .split('::')
          .map { |str| tools.string_tools.underscore(str) }
          .join(':')
      end

      def invalid_full_name_format_message
        'full_name does not match format category:sub_category:do_something'
      end

      def tools = SleepingKingStudios::Tools::Toolbelt.instance
    end
  end
end
