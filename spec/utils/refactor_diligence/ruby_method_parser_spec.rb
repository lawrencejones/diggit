require 'utils/refactor_diligence/ruby_method_parser'

RSpec.describe(RefactorDiligence::RubyMethodParser) do
  subject(:ruby_file) { described_class.new(contents) }

  describe('.methods') do
    subject(:methods) { ruby_file.methods }

    context 'with unscoped method' do
      let(:contents) do
        %(def non_scoped_two_line_method(param)
            puts 'line 1'
            puts 'line 2'
          end)
      end

      it { is_expected.to include('non_scoped_two_line_method' => 4) }
    end

    context 'with unscoped class' do
      let(:contents) do
        %(class NonModuleClass
            def initialize(param)
              @assigned_param = param
            end

            def two_line_method
              puts "1 - \#{@assigned_param}"
              puts "2 - \#{@assigned_param}"
            end
          end)
      end

      it 'parses class methods' do
        is_expected.to include(
          'NonModuleClass::initialize' => 3,
          'NonModuleClass::two_line_method' => 4
        )
      end
    end

    context 'with module namespace' do
      let(:contents) do
        %(module Foo
            def module_method
            end

            class Bar
              def initialize(param)
                puts 'line 1'
              end

              def two_line_method
                puts 'my first line'
                puts 'my second line'
              end
            end
          end)
      end

      it { is_expected.to include('Foo::module_method' => 2) }

      it 'parses classes within modules' do
        is_expected.to include(
          'Foo::Bar::initialize' => 3,
          'Foo::Bar::two_line_method' => 4
        )
      end
    end
  end
end
