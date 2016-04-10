require 'diggit/analysis/refactor_diligence/ruby_method_parser'

RSpec.describe(Diggit::Analysis::RefactorDiligence::RubyMethodParser) do
  subject(:ruby_file) { described_class.new(contents, file: 'file.rb') }

  describe('.methods') do
    subject(:methods) { ruby_file.methods }

    context 'with invalid ruby syntax' do
      let(:contents) { %(this ain't ruby y'all) }

      it { is_expected.to eql({}) }
    end

    context 'with unscoped method' do
      let(:contents) do
        %(def two_line_method(param)
            puts 'line 1'
            puts 'line 2'
          end)
      end

      it { is_expected.to include('two_line_method' => { lines: 4, loc: 'file.rb:1' }) }
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
          'NonModuleClass::initialize' => { loc: 'file.rb:2', lines: 3 },
          'NonModuleClass::two_line_method' => { loc: 'file.rb:6', lines: 4 }
        )
      end
    end

    context 'with module namespace' do
      let(:contents) do
        %(module Foo
            def method
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

      it { is_expected.to include('Foo::method' => { loc: 'file.rb:2', lines: 2 }) }

      it 'parses classes within modules' do
        is_expected.to include(
          'Foo::Bar::initialize' => { loc: 'file.rb:6', lines: 3 },
          'Foo::Bar::two_line_method' => { loc: 'file.rb:10', lines: 4 }
        )
      end
    end
  end
end
