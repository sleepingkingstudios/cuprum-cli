# frozen_string_literal: true

require 'cuprum/cli/files/generator'

require 'cuprum/cli/rspec/deferred/generators_examples'

RSpec.describe Cuprum::Cli::Files::Generator do
  include Cuprum::Cli::RSpec::Deferred::GeneratorsExamples

  subject(:generator) do
    described_class.new(file_system:, standard_io:, point:)
  end

  let(:described_class) { Spec::GeneratorWithParameters }
  let(:files) do
    template = <<~TEMPLATE
      ---
      distance: <%= distance %>
    TEMPLATE

    { 'templates' => { 'point.yml.erb' => template } }
  end
  let(:file_system) do
    Cuprum::Cli::Dependencies::FileSystem::Mock.new(files:)
  end
  let(:standard_io) { Cuprum::Cli::Dependencies::StandardIo::Mock.new }
  let(:point)       { Spec::Point.new(x: 3, y: 4) }

  example_class 'Spec::Point', Data.define(:x, :y)

  example_class 'Spec::GeneratorWithParameters', Cuprum::Cli::Files::Generator \
  do |klass|
    klass.option :point, type: Spec::Point, required: true

    klass.output 'point.yml', template: 'templates/point.yml.erb'

    klass.define_method :distance do
      Math.sqrt(point.x ** 2 + point.y ** 2).round(1).to_s
    end

    klass.define_method :parameters do
      super().merge(distance:)
    end
  end

  include_deferred 'should output file',
    'point.yml',
    template: 'templates/point.yml.erb'
end
