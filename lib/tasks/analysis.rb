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

  desc 'Re-enqueues analysis for pulls missing reporters'
  task :backfill do
    require 'diggit/analysis/pipeline'
    require 'diggit/jobs/analyse_pull'
    require 'diggit/models/pull_analysis'

    include Diggit

    fully_reported_analyses = PullAnalysis.
      where.contains(reporters: Analysis::Pipeline.reporters).
      pluck(:id)
    incomplete_reported_analyses = PullAnalysis.
      where.not(id: fully_reported_analyses)

    puts("Found #{incomplete_reported_analyses.count} incomplete analyses!")
    ActiveRecord::Base.transaction do
      incomplete_reported_analyses.each do |analysis|
        puts("  - #{analysis.project.gh_path}/pull/#{analysis.pull} "\
             "#{analysis.base.first(7)}...#{analysis.head.first(7)}")
        Jobs::AnalysePull.
          enqueue(analysis.project.gh_path,
                  analysis.pull,
                  analysis.head,
                  analysis.base)
      end
    end

    puts('Done!')
  end

  desc 'Examines the comments made to a pull request'
  task :examine, [:gh_path, :pull] do |_, args|
    require 'terminal-table'
    require 'diggit/models/pull_analysis'

    analyses = PullAnalysis.
      for_project(args.fetch(:gh_path)).
      where(pull: args.fetch(:pull)).
      order(:created_at)

    puts("Found #{analyses.count} analyses for this pull!")

    comment_indexes = analyses.
      flat_map(&:comments).
      map { |comment| comment.slice('report', 'index') }.
      uniq

    rows = comment_indexes.map do |comment|
      ["#{comment['report']}##{comment['index']}", *analyses.map do |a|
        a.comments.any? { |c| c.slice('report', 'index') == comment } ? 'X' : ''
      end]
    end
    puts(Terminal::Table.new(rows: rows))
  end
end
