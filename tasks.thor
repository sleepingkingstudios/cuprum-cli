# frozen_string_literal: true

require 'byebug'
require 'thor'
require 'cuprum/cli'

module Cuprum::Cli::Metadata::ClassMethods
  def full_description?
    !(@full_description.nil? || @full_description.empty?)
  end
end

class ThorRegistry < Cuprum::Cli::Registry
  def register(command, **)
    super

    build_task(command)

    self
  end

  private

  def build_task(command)
    *segments, name = command.full_name.split(':')
    task_namespace  = segments.join
    argument_names  =
      command
      .arguments
      .map { |arg| " #{'...' if arg.variadic?}#{arg.name.upcase}"}
      .join

    Class.new(Thor) do
      if task_namespace.empty?
        namespace('default')
      else
        namespace(task_namespace)
      end

      desc("#{command.short_name}#{argument_names}", command.description)

      long_desc(command.full_description) if command.full_description?

      command.options.each do |option_name, command_option|
        params = {}
        params[:desc]     = command_option.description
        params[:required] = command_option.required?
        params[:type]     = command_option.type.name.downcase
        params[:aliases]  = command_option.aliases

        option(option_name, **params)
      end

      define_method(command.short_name) do |*arguments|
        tools = SleepingKingStudios::Tools::Toolbelt.instance
        opts  = tools.hash_tools.convert_keys_to_symbols(options)

        command.new.call(*arguments, **opts)
      end
    end
  end
end

registry = ThorRegistry.new
registry.register(Cuprum::Cli::Commands::EchoCommand)
