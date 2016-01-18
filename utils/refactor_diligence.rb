#!/usr/bin/env ruby
require_relative './refactor_diligence/profile'

def usage
  prog = File.basename(__FILE__)
  puts %(
    Desc:  Produce code profile for given ruby repo
    Usage: #{prog} <repo>
    Examples...

        #{prog} /Projects/arm

    Example output...

        [135, 89, 14, 2, 1, 1, 1, 1, 1]

    The nth element of the profile is the number of methods detected that have
    increased in size over the last n consecutive changes.
  )
end

usage || exit(-1) unless ARGV.count == 1
repo_path = File.realpath(ARGV.first)

RefactorDiligence::Profile.
  temp_git_repo(repo_path) do |repo|
    profile = RefactorDiligence::Profile.
      new(repo, initial_ref: 'master')

    puts %(
    Profile for #{repo_path} is...

      [#{profile.array_profile.join(', ')}]

    ...for #{profile.array_profile.inject(:+)} methods.
    )
  end
