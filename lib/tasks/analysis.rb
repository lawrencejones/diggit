namespace :analysis do
  def unique_comments(analyses)
    analyses.
      flat_map(&:comments).
      map { |comment| comment.slice('report', 'index') }.
      uniq
  end

  desc 'Flushes redis cache and resets min_support params'
  task :reset do
    require 'diggit/models/project'
    require 'diggit/services/cache'

    puts("Flushing redis cache: #{Diggit::Services::Cache.conn.flushall}")

    updated = Project.update_all(min_support: 0)
    puts("Reset min_support on #{updated} projects")
  end

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

  desc 'Prints the pulls where created_at does not reflect the final commit'
  task :verify_last_analysis, [:gh_path] do |_, args|
    require 'diggit/models/project'
    require 'diggit/models/pull_analysis'
    require 'diggit/github/client'

    project = Project.find_by(gh_path: args.fetch(:gh_path))
    pulls = PullAnalysis.for_project(args.fetch(:gh_path)).pluck('DISTINCT pull').sort
    gh_client = Diggit::Github.client_for(project)

    pulls.each do |pull|
      pr = gh_client.pull(project.gh_path, pull)
      next unless pr.state == 'closed'

      close_head = pr.head.sha.first(7)
      last_analysis_head = PullAnalysis.
        where(project: project, pull: pull).
        order(:created_at).last.head.first(7)

      unless close_head == last_analysis_head
        puts("  - #{project.gh_path}/pull/#{pull} #{last_analysis_head} #{close_head}")
      end
    end
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

  def analysis_comment_rows(analyses)
    analyses = analyses.order(:created_at)
    unique_comments(analyses).map do |comment|
      ["#{comment['report']}##{comment['index']}", *analyses.map do |a|
        a.comments.any? { |c| c.slice('report', 'index') == comment } ? 'X' : ''
      end]
    end
  end

  desc 'Examines entire project'
  task :examine_project, [:gh_path] do |_, args|
    require 'terminal-table'
    require 'colorize'
    require 'diggit/models/pull_analysis'

    rows = []
    gh_path = args.fetch(:gh_path)

    pulls = PullAnalysis.for_project(gh_path).pluck('DISTINCT pull').sort
    pulls.each_with_index do |pull, i|
      analyses = PullAnalysis.for_project(gh_path).where(pull: pull)
      next if analyses.with_comments.empty?
      rows << :separator unless rows.empty?
      rows << ["#{gh_path}/pull/#{pull}".colorize(:light_blue)]
      rows << :separator
      rows.concat(analysis_comment_rows(analyses))
      rows << :separator
      rows << []
    end

    rows.pop(2)
    puts(Terminal::Table.new(rows: rows))
  end

  desc 'Examines the comments made to a pull request'
  task :examine, [:gh_path, :pull] do |_, args|
    require 'terminal-table'
    require 'diggit/models/pull_analysis'

    analyses = PullAnalysis.
      for_project(args.fetch(:gh_path)).
      where(pull: args.fetch(:pull))

    puts("Found #{analyses.count} analyses for this pull!")
    puts(Terminal::Table.new(rows: analysis_comment_rows(analyses)))
  end

  desc 'Generate analysis duration statistics'
  task :duration_stats do
    require 'terminal-table'
    require 'descriptive-statistics'
    require 'rugged'
    require 'diggit/models/pull_analysis'
    require 'diggit/models/project'
    require 'diggit/services/git_helpers'

    # Project, No of Files, Analyses, Duration{avg,90th,max}
    def initial_rows
      [['Project', 'Files', 'Commits', 'Analyses', 'Avg', 'STD', '90%th', 'Max'],
       :separator]
    end

    def git_counts(project)
      app_root = Rake.application.original_dir
      cache_path = File.join(app_root, 'tmp/project_cache', project.gh_path)

      return [nil, nil] unless Dir.exist?(cache_path)
      rugged = Rugged::Repository.new(cache_path)
      repo = Class.new.include(Diggit::Services::GitHelpers).new(rugged)

      master = %w(master trunk devel).
        map { |b| rugged.branches["origin/#{b}"] }.
        compact.first

      no_of_files = repo.ls_files(master.target).count
      no_of_commits = repo.send(:command, 'rev-list', '--all', '--count').to_i

      [no_of_files, no_of_commits]
    end

    PullAnalysis.with_comments.where('duration > 0').pluck('DISTINCT project_id').
      each_with_object(initial_rows) do |project_id, rows|
        project = Project.find(project_id)
        analyses = PullAnalysis.where(project: project)
        durations = analyses.where('duration > 0').pluck(:duration)
        stats = DescriptiveStatistics::Stats.new(durations)

        rows << [project.gh_path, *git_counts(project), analyses.count,
                 stats.mean.to_f.round(3),
                 stats.standard_deviation.to_f.round(3),
                 stats.value_from_percentile(90).to_f.round(3),
                 stats.max.to_f.round(3)]
      end.tap { |rows| puts(Terminal::Table.new(rows: rows)) }
  end

  desc 'Generate hit rates for pulls'
  task :hit_rates do
    require 'terminal-table'
    require 'descriptive-statistics'
    require 'rugged'
    require 'diggit/models/pull_analysis'
    require 'diggit/models/project'

    def initial_rows
      [['Project', 'Pulls w/ Comments', 'Total Pulls', 'Hit Rate'], :separator]
    end

    PullAnalysis.with_comments.pluck('DISTINCT project_id').
      each_with_object(initial_rows) do |project_id, rows|
        project = Project.find(project_id)
        analyses = PullAnalysis.where(project: project)

        total_pulls = analyses.pluck('DISTINCT pull').count
        pulls_with_comments = analyses.with_comments.pluck('DISTINCT pull').count

        rows << [project.gh_path,
                 pulls_with_comments,
                 total_pulls,
                 "#{100 * pulls_with_comments / total_pulls}%"]
      end.tap { |rows| puts(Terminal::Table.new(rows: rows)) }
  end

  desc 'Generates stats about analysis comments'
  task :stats do
    require 'terminal-table'
    require 'diggit/analysis/pipeline'
    require 'diggit/models/pull_analysis'
    require 'diggit/models/project'
    require 'diggit/services/pull_comment_stats'

    def counter
      Diggit::Analysis::Pipeline.reporters.map { |r| [r, total: 0, resolved: 0] }.to_h
    end

    def initial_rows
      [['Project', 'Pulls', 'Totals', *counter.keys], :separator]
    end

    def reporter_cell(resolved:, total:)
      pct = 100 * resolved.to_f / total.to_f
      pct = 0 if pct.nan?

      "#{resolved}/#{total} (#{pct.round(1)}%)"
    end

    # Project,    Pulls, Totals,      Reporter
    # owner/repo, 5,     15/60 (25%), 15/60 (25%)
    Project.order(:gh_path).each_with_object(initial_rows) do |project, rows|
      project_analyses = PullAnalysis.where(project: project)
      next if project_analyses.with_comments.empty?

      rows << row = [project.gh_path, project_analyses.count('DISTINCT pull').to_s]
      report_counts = counter

      # Compute stats per pull and aggregate
      project_analyses.with_comments.group_by(&:pull).each do |pull, analyses|
        stats = Diggit::Services::PullCommentStats.new(project, pull)
        report_counts.each do |reporter, count|
          count[:total] += stats.comments.select { |c| c['report'] == reporter }.size
          count[:resolved] += stats.resolved.select { |c| c['report'] == reporter }.size
        end
      end

      # Compute project total of all reporters
      project_total = report_counts.values.
        each_with_object(total: 0, resolved: 0) do |report_count, project_count|
          project_count[:total] += report_count[:total]
          project_count[:resolved] += report_count[:resolved]
        end

      row << reporter_cell(project_total)
      report_counts.each { |_, report_total| row << reporter_cell(report_total) }
    end.tap { |rows| puts(Terminal::Table.new(rows: rows)) }
  end
end
