require 'git'
require 'fileutils'
require 'logger'
require 'hamster/hash'
require 'hamster/list'
require 'active_support/core_ext/array'

require_relative './repo_scanner'
require_relative './ruby_method_parser'

module RefactorDiligence
  # Can compute the refactor diligence profile of a ruby repo, presenting the data
  # in either summary array form or method size histories.
  class Profile
    def self.temp_git_repo(repo_path)
      Dir.mktmpdir('refactor-diligence') do |scratch_path|
        FileUtils.cp_r(File.join(repo_path, '.git'), File.join(scratch_path, '.git'))
        yield Git.open(scratch_path)
      end
    end

    def initialize(repo, initial_ref: 'master')
      @repo = repo
      @initial_ref = initial_ref
    end

    def method_histories
      @method_histories ||= compute_method_histories
    end

    def array_profile
      @array_profile ||=
        method_histories.values.each_with_object([]) do |sizes, profile|
          profile[sizes.count] ||= 0
          profile[sizes.count] += 1
        end.map { |value| value || 0 }.from(1)
    end

    private

    attr_reader :repo, :initial_ref

    def compute_method_histories
      tracked = method_sizes.first.keys
      method_sizes.each_with_object(initial_method_profile) do |sizes, profile|
        methods_that_were_reduced = tracked.
          select { |method| sizes[method] > profile[method].last }
        tracked -= methods_that_were_reduced

        tracked.
          select { |method| sizes[method] < profile[method].last }.
          each   { |method| profile[method].push(sizes[method]) }
      end
    end

    def method_sizes
      @method_sizes ||= RepoScanner.new(repo).scan_back_from(initial_ref)
    end

    def initial_method_profile
      method_sizes.first.map { |key, size| [key, [size]] }
    end
  end
end
