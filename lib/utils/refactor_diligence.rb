#!/usr/bin/env ruby
require 'json'
require 'commander/import'
require_relative './refactor_diligence/profile'

program :name, 'Refactor Diligence'
program :version, '1.0.0'
program :description, 'Analyze ruby methods for continual increase in size'
program :help, 'Profile', %(
Example array profile...

    [135, 89, 14, 2, 1, 1, 1, 1, 1]

The nth element of the profile is the number of methods detected that have
increased in size over the last n consecutive changes.)

command :profile do |c|
  c.syntax = 'profile <repo> [options]'
  c.description = 'Scan repo to generate a refactor profile for each method'

  c.option '--stream-progress', 'Logs commit SHAs during repo scan'
  c.option '--output-json', 'Outputs final profile as json object'

  c.action do |(repo_path), options|
    RefactorDiligence::Profile.temp_git_repo(repo_path) do |repo|
      ENV['LOG_LEVEL'] = 'debug' if options.stream_progress
      profile = RefactorDiligence::Profile.new(repo, initial_ref: 'master')

      if options.output_json
        puts(JSON.generate(
               repo_path: File.realpath(repo_path),
               profile: profile.array_profile,
               method_histories: profile.method_histories.to_h))
      else
        puts("[#{profile.array_profile.join(', ')}]")
      end
    end
  end
end
