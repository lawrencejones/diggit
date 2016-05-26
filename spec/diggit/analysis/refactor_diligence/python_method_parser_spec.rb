require 'diggit/analysis/refactor_diligence/python_method_parser'

RSpec.describe(Diggit::Analysis::RefactorDiligence::PythonMethodParser) do
  subject(:python_file) { described_class.new(contents, file: 'file.py') }

  describe '.methods' do
    subject(:methods) { python_file.methods }

    context 'with invalid python syntax' do
      let(:contents) { %(hiss sputter hissss) }

      it { is_expected.to eql({}) }
    end

    context 'with global function' do
      let(:contents) { <<-PYTHON }
      def global_function():
      \tmodify_global_state()
      \treturn 'global yo'
      PYTHON

      it { is_expected.to include('global_function' => { lines: 3, loc: 'file.py:1' }) }
    end

    context 'with function within function' do
      let(:contents) { <<-PYTHON }
      def global_function():
      \tdef nested_function():
      \t\tmodify_global_state()
      \tnested_function()
      PYTHON

      it 'parses nested function' do
        is_expected.to include(
          'global_function' => { lines: 4, loc: 'file.py:1' },
          'global_function::nested_function' => { lines: 2, loc: 'file.py:2' }
        )
      end
    end

    context 'with class method' do
      let(:contents) { <<-PYTHON }
      class PythonClass(object):

      \tdef __init__(self, name):
      \t\tself.name = name
      \t\tprint(self.name)
      PYTHON

      it 'parses class __init__' do
        is_expected.to include('PythonClass::__init__' => { lines: 3, loc: 'file.py:3' })
      end
    end
  end
end
