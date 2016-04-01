require 'git'
require 'fileutils'
require 'utils/refactor_diligence/repo_scanner'

RSpec.describe(RefactorDiligence::RepoScanner) do
  subject(:scanner) { described_class.new(@repo) }
  let(:tmp) { Dir.mktmpdir }

  before do
    Dir.chdir(tmp) do
      @repo = repo = Git.init(tmp)

      File.write('./child.rb', %(
      class Child
        def initialize(name)
          @name = name
        end

        def say_name
          puts(name)
        end
      end))

      repo.add('./child.rb')
      repo.commit('Initial commit')

      File.write('./child.rb', %(
      class Child
        def initialize(name)
          @name = name
        end

        def say_name
          # Add explanatory comment
          puts(name)
        end

        def shout_name
          puts(name.upcase)
        end
      end))

      repo.add('./child.rb')
      repo.commit('Second commit')
    end
  end

  after { FileUtils.rm_rf(tmp) }

  describe('.scan_back_from') do
    subject(:method_sizes) { scanner.scan_back_from('master') }
    let(:no_of_commits) { 2 }

    it 'counts all commits' do
      expect(method_sizes.length).to equal(no_of_commits)
    end

    it 'tracks all methods in latest commit' do
      expect(method_sizes.first.keys).to include(*%w(
                                                   Child::initialize
                                                   Child::say_name
                                                   Child::shout_name
                                                 ))
    end

    it 'detects when methods have been changed in size' do
      expect(method_sizes[0]['Child::say_name']).to equal(4)
      expect(method_sizes[1]['Child::say_name']).to equal(3)
    end
  end
end
