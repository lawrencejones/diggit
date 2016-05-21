namespace :analysis do
  desc 'Runs an analysis on the given pull'
  task :run, [:gh_path, :pull] do |_, args|
    require 'diggit/github/client'
    require 'diggit/jobs/analyse_pull'
    require 'diggit/models/pull_analysis'

    pr = Diggit::Github.client.pull(args.fetch(:gh_path), args.fetch(:pull).to_i)
    puts("Identified pull with #{pr.base.sha.first(7)}...#{pr.head.sha.first(7)}")

    existing_pull_analysis = PullAnalysis.
      for_project(args.fetch(:gh_path)).
      find_by(pull: args.fetch(:pull))

    unless existing_pull_analysis.nil?
      puts('Found existing pull analysis, destroying...')
      existing_pull_analysis.destroy
    end

    puts('Running analysis...')
    Que.mode = :sync
    Diggit::Jobs::AnalysePull.
      enqueue(args.fetch(:gh_path), args.fetch(:pull), pr.head.sha, pr.base.sha)

    puts('Done!')
  end
end
