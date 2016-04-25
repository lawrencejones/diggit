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

      expect(client).to receive(:add_comment).with(repo, pull, "hello\nworld")
      generator.push
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
          with(repo, pull, "hello\nworld", 'head-sha', 'Gemfile.rb', 7)
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
end
