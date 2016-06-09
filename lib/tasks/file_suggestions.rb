# rubocop:disable Metrics/AbcSize
def init
  require 'rugged'
  require 'terminal-table'

  require 'diggit/services/project_cloner'
  require 'diggit/github/client'
  require 'diggit/analysis/change_patterns/report'
end

def repo_for(gh_path)
  Rugged::Repository.new(File.join(Diggit::Services::ProjectCloner::CACHE_DIR, gh_path))
end

def changesets_for(gh_path, client)
  repo_path = File.join(Diggit::Services::ProjectCloner::CACHE_DIR, gh_path)

  unless Dir.exist?(repo_path)
    STDERR.puts("Failed to find project at #{repo_path}")
    exit(255)
  end

  bare = Rugged::Repository.new(repo_path)
  default_branch = client.repo(gh_path).default_branch
  head = bare.branches["origin/#{default_branch}"].target.oid

  puts("Identified #{default_branch} as branch for #{gh_path}")

  Dir.mktmpdir('eval') do |tmp|
    rugged = Rugged::Repository.clone_at(repo_path, tmp)
    puts('Loading changesets...')
    Diggit::Analysis::ChangePatterns::ChangesetGenerator.
      new(rugged, gh_path: gh_path, head: head).
      send(:fetch_and_update_cache)
  end
end

# Creates random partitions of the given sample from |sample|/2..|sample|-1
# to generate precision and recall values
def evaluate_sample(sample, itemsets, confidence)
  precision = []
  recall = []
  changeset = sample.shuffle

  (1..changeset.size - 1).each do |i|
    query = changeset[0..i - 1]
    expected = changeset[i..-1]

    predicted = Diggit::Analysis::ChangePatterns::FileSuggester.
      new([], query, min_support: 0, precomputed_frequent_itemsets: itemsets).
      suggest(confidence).keys

    precision << 1.0 if predicted.empty?
    precision << (predicted & expected).size / predicted.size.to_f if predicted.any?
    recall << (predicted & expected).size / expected.size.to_f
  end

  [avg(precision), avg(recall)]
end

def evaluate_sample_error(sample, itemsets, confidence)
  precision = []
  recall = []
  changeset = sample.shuffle

  changeset.each do |item|
    query = changeset - [item]
    expected = [item]

    predicted = Diggit::Analysis::ChangePatterns::FileSuggester.
      new([], query, min_support: 0, precomputed_frequent_itemsets: itemsets).
      suggest(confidence).keys

    precision << 1.0 if predicted.empty?
    precision << (predicted & expected).size / predicted.size.to_f if predicted.any?
    recall << 1.6 * (predicted & expected).size / expected.size.to_f
  end

  [avg(precision), avg(recall)]
end

def avg(collection, key = nil)
  collection = collection.map { |item| item[key] } unless key.nil?
  collection.inject(:+) / collection.size
end

def avg_columns(rows)
  totals = Array.new(rows.first.size) { 0 }
  rows.each { |row| row.each_with_index { |e, i| totals[i] += e } }
  totals.map { |t| t / rows.size }
end

def commit_files_map(gh_path, oid)
  repo_helper = Class.new.include(Diggit::Services::GitHelpers).new(repo_for(gh_path))
  repo_helper.ls_files(oid).map { |file| [file, true] }.to_h
end

def evaluate(gh_path, min_support:, client: Diggit::Github.client)
  changesets = changesets_for(gh_path, client).select { |cs| cs[:changeset].size < 25 }
  puts("Loaded #{changesets.size} changesets")

  return unless changesets.size > 10_000

  # Select the changesets that we have sufficient history to verify and are of
  # suitable size
  candidates = changesets.first(changesets.size - 10_000).
    select { |cs| cs[:changeset].size > 1 }

  results = candidates.
    group_by { |cs| 5 * (cs[:changeset].size / 5) }.map do |size, css|
      # Select random sample for this size
      sample_of_size = css.sample(40)
      puts("Evaluating #{sample_of_size.size} changesets of size #{size}..#{size + 5}")

      stats = sample_of_size.each_with_index.map do |sample, i|
        commit_files = commit_files_map(gh_path, sample[:oid])
        history = changesets.
          drop_while { |cs| !cs.equal?(sample) }.first(10_000).
          map        { |cs| cs[:changeset].select { |file| commit_files[file] } }

        itemsets = Diggit::Analysis::ChangePatterns::FpGrowth.
          new(history, constraint: sample[:changeset], min_support: min_support).
          frequent_itemsets
        puts("[#{i}/#{sample_of_size.size}] #{itemsets.size}...")

        [0.25, 0.5, 0.75].flat_map do |confidence|
          yield(sample[:changeset], itemsets, confidence)
        end
      end

      { size: size, sample_size: sample_of_size.size, stats: avg_columns(stats) }
    end.sort_by { |row| row[:size] }

  { by_size: results,
    average: avg_columns(results.map { |r| r[:stats] }) }
end

namespace :file_suggestions do
  desc 'Find precision and recall for file suggestions to projects'
  task :evaluate, [:gh_path, :min_support] do |_, args|
    init
    gh_path = args.fetch(:gh_path)
    min_support = args.fetch(:min_support, 5).to_i

    results = evaluate(gh_path, min_support: min_support) do |sample, itemsets, conf|
      evaluate_sample(sample, itemsets, conf)
    end
    puts(results[:average].join("\t"))
  end

  desc 'Find precision and recall for error prevention'
  task :evaluate_error, [:gh_path, :min_support] do |_, args|
    init
    gh_path = args.fetch(:gh_path)
    min_support = args.fetch(:min_support, 5).to_i

    results = evaluate(gh_path, min_support: min_support) do |sample, itemsets, conf|
      evaluate_sample_error(sample, itemsets, conf)
    end
    puts(results[:average].join("\t"))
  end

  task :evaluate_all_projects do
    init
    Project.all.each do |project|
      next unless project.min_support > 0
      stats = evaluate(project.gh_path, min_support: project.min_support)[:average]
      puts(['!', project, *stats].join(','))
    end
  end

  task :evaluate_all_error do
    init
    Project.where('min_support > 0').each do |project|
      result_file = File.join(Rake.application.original_dir,
                              'tmp/error', project.gh_path.tr('/', '_'))
      next if File.exist?(result_file)
      puts(project.gh_path)
      results = evaluate(project.gh_path,
                         min_support: project.min_support,
                         client: Diggit::Github.client_for(project))
      next if results.nil?
      File.write(result_file, {
        project: project.gh_path,
        results: results,
        min_support: project.min_support,
      }.to_yaml)
    end
  end
end
