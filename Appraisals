# frozen_string_literal: true

require 'appraisal'

::Appraisal::DependencyList.class_exec do # rubocop:disable Style/RedundantConstantBase
  def each_key(&) = @dependencies.each_key(&)
end

::Appraisal::Gemfile.class_exec do # rubocop:disable Style/RedundantConstantBase
  attr_reader :groups
end

# Helper methods for generating appraisals.
module AppraisalHelpers
  INTEGRATIONS = {
    thor: %w[thor]
  }.freeze

  def remove_docs
    gemfile
      .groups[[:docs]]
      .dependencies
      .each_key { |key| group(:docs) { remove_gem(key) } }
  end

  def remove_integrations(except: [])
    except = [except] unless except.is_a?(Array)

    INTEGRATIONS.each do |key, gems|
      next if except.include?(key)

      gems.each { |gem_name| remove_gem(gem_name) }
    end
  end
end

appraise('default') do
  extend AppraisalHelpers

  remove_docs
  remove_integrations
end

appraise 'integrations/thor' do
  extend AppraisalHelpers

  remove_docs
  remove_integrations(except: :thor)
end
