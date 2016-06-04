require 'diggit/github/comment_generator'

RSpec.describe(Diggit::Github::CommentGenerator) do
  subject(:generator) { described_class.new(repo, pull, client) }

  let(:repo) { 'lawrencejones/diggit' }
  let(:pull) { 43 }
  let(:client) { instance_double(Octokit::Client) }

  before do
    allow(Diggit::Github::Diff).
      to receive(:from_pull_request).
      with(repo, pull, client).
      and_return(diff)
  end

  let(:diff) { instance_double(Diggit::Github::Diff, head: 'head-sha') }

  describe '#add_comment' do
    it 'aggregates comments for pushing' do
      generator.add_comment('hello')
      generator.add_comment('world')

      expect(client).to receive(:add_comment).with(repo, pull, "hello\n\nworld")
      generator.push
    end

    # Whilst pushing this option into the diff makes the api less consistent, it
    # dramatically improves the call sites for the generator.
    context 'with location' do
      it 'delegates to add_comment_on_file' do
        expect(generator).to receive(:add_comment_on_file).with('hello', 'Gemfile.rb', 5)
        generator.add_comment('hello', 'Gemfile.rb:5')
      end
    end
  end

  describe '#add_comment_on_file' do
    context 'when location is present in diff' do
      before { allow(diff).to receive(:index_for).with('Gemfile.rb', 5).and_return(7) }

      it 'will aggregate comments for pushing' do
        generator.add_comment_on_file('hello', 'Gemfile.rb', 5)
        generator.add_comment_on_file('world', 'Gemfile.rb', 5)

        expect(client).
          to receive(:create_pull_comment).
          with(repo, pull, "hello\n\nworld", 'head-sha', 'Gemfile.rb', 7)
        generator.push
      end
    end

    context 'when line not in diff' do
      before { allow(diff).to receive(:index_for).with('Gemfile.rb', 5).and_return(nil) }

      it 'defaults to diff_index 1' do
        generator.add_comment_on_file('hello', 'Gemfile.rb', 5)

        expect(client).
          to receive(:create_pull_comment).
          with(repo, pull, 'hello', 'head-sha', 'Gemfile.rb', 1)
        generator.push
      end
    end

    context 'when file not in diff' do
      before do
        allow(diff).
          to receive(:index_for).
          with('Gemfile.rb', 5).
          and_raise(Diggit::Github::Diff::FileNotFound)
      end

      it 'comments on entire pr with location' do
        generator.add_comment_on_file('hello', 'Gemfile.rb', 5)

        expect(client).
          to receive(:add_comment).
          with(repo, pull, 'At Gemfile.rb:5 - hello')
        generator.push
      end
    end
  end

  describe '.pending' do
    before do
      allow(diff).to receive(:index_for).with('Gemfile.rb', 5).and_return(7)
      allow(diff).to receive(:index_for).with('Gemfile.rb', 6).and_return(8)
    end

    it 'number of comments waiting to be pushed' do
      generator.add_comment('main thread')
      generator.add_comment('again main thread')
      generator.add_comment('on Gemfile at line 5', 'Gemfile.rb:5')
      generator.add_comment_on_file('again on Gemfile at line 5', 'Gemfile.rb', 5)
      generator.add_comment_on_file('another at Gemfile line 6', 'Gemfile.rb', 6)

      expect(generator.pending).to eql(3)
    end
  end
end
