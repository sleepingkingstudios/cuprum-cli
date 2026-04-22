# frozen_string_literal: true

require 'cuprum/command'

require 'cuprum/cli/commands/file'
require 'cuprum/cli/errors/files/template_not_resolved'

module Cuprum::Cli::Commands::File
  # Utility command for resolving a template and parameterized values.
  class ResolveTemplate < Cuprum::Command
    # @param templates [Array<Hash>] the defined templates.
    def initialize(templates:)
      super()

      @templates = templates
    end

    # @return [Array<Hash>] the defined templates.
    attr_reader :templates

    private

    def default_params(file_path:, **params) # rubocop:disable Metrics/MethodLength
      dir_name   = File.dirname(file_path)
      ext_name   = File.extname(file_path)
      base_name  = File.basename(file_path)
      short_name = base_name.split('.').first

      {
        base_name:,
        dir_name:,
        ext_name:,
        file_path:,
        short_name:,
        **params
      }
    end

    def filter_templates(except:, file_templates:, only:)
      file_templates = [file_templates] unless file_templates.is_a?(Array)
      except         = Array(except).map(&:to_s)
      only           = Array(only).map(&:to_s)

      unless except.empty?
        file_templates = reject_templates(file_templates, *except)
      end

      unless only.empty?
        file_templates = select_templates(file_templates, *only)
      end

      file_templates
    end

    def match_pattern(pattern, file_path)
      case pattern
      when Proc
        pattern.call(file_path)
      when Regexp
        match_regexp(pattern, file_path)
      when String
        { file_path: } if file_path.end_with?(pattern)
      else
        # :nocov:
        false
        # :nocov:
      end
    end

    def match_regexp(pattern, file_path)
      pattern
        .match(file_path)
        &.named_captures
        &.then { |captures| tools.hash_tools.convert_keys_to_symbols(captures) }
    end

    def process(file_path, except: [], only: []) # rubocop:disable Metrics/MethodLength
      templates.each do |hsh|
        params = match_pattern(hsh.fetch(:pattern), file_path)

        next unless params

        file_templates = hsh.fetch(:templates)
        file_templates = step do
          filter_templates(file_templates:, except:, only:)
        end

        step { require_templates(file_path:, file_templates:, except:, only:) }

        return success([file_templates, default_params(file_path:, **params)])
      end

      message = 'no template matching file path'

      failure(template_not_resolved_error(file_path:, message:))
    end

    def reject_templates(file_templates, *filters)
      file_templates.reject do |template|
        types = template.fetch(:types, Array(template[:type])).map(&:to_s)

        types.any? { |type| filters.include?(type) }
      end
    end

    def require_templates(file_path:, file_templates:, except:, only:)
      return unless file_templates.empty?

      options = {}
      options[:except] = except unless except.empty?
      options[:only]   = only   unless only.empty?

      error = template_not_resolved_error(
        file_path:,
        message:   'all templates filtered out',
        options:
      )

      failure(error)
    end

    def select_templates(file_templates, *filters)
      file_templates.select do |template|
        types = template.fetch(:types, Array(template[:type])).map(&:to_s)

        types.any? { |type| filters.include?(type) }
      end
    end

    def template_not_resolved_error(**)
      Cuprum::Cli::Errors::Files::TemplateNotResolved.new(**)
    end

    def tools = @tools ||= SleepingKingStudios::Tools::Toolbelt.instance
  end
end
