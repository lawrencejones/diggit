# rubocop:disable Metrics/AbcSize
namespace :frequent_pattern do
  BENCHMARK_TASK_ARGS = [:support_range, :max_items, :no_of_changesets].freeze

  desc 'Walk rails repository to fill changeset cache'
  task :walk_rails, [:rails_path] do |_, args|
    require 'diggit/analysis/change_patterns/changeset_generator'

    puts('Loading rails repo...')
    rails_path = File.join(Rake.application.original_dir, args.fetch(:rails_path))
    rails = Rugged::Repository.new(rails_path)

    puts('Walking commit history...')
    changesets = Diggit::Analysis::ChangePatterns::ChangesetGenerator.
      new(rails, gh_path: 'frequent_pattern/rails').changesets

    puts("Loaded #{changesets.size} changesets into cache!")
  end

  # Runs and profiles blocks that generate frequent pattern sets from the rails
  # changesets.
  def benchmark_fp_discovery(algorithm, args, _dump_dir)
    require 'yaml'
    require 'ruby-prof'
    require 'fileutils'

    require 'diggit/services/cache'

    # min_support = args.fetch(:min_support, 10).to_i
    support_range = Range.new(*args.fetch(:support_range).split('..').map(&:to_i))
    max_items = args.fetch(:max_items, 20).to_i
    no_of_changesets = args.fetch(:no_of_changesets, 10_000).to_i
    patterns = nil

    changesets = Diggit::Services::Cache.get('frequent_pattern/rails/changesets').
      map { |entry| entry[:changeset] }.
      first(no_of_changesets)
    puts("Loaded #{changesets.size} changesets!")

    support_range.to_a.reverse.each do |min_support|
      puts("Starting: #{{ min_support: min_support, max_items: max_items }}...")
      run_time = Benchmark.measure do
        patterns = algorithm.new(changesets,
                                 min_support: min_support,
                                 max_items: max_items).frequent_itemsets
      end
      puts("Found #{patterns.size} frequent patterns!")
      puts("#{run_time}\n")
    end
  end

  namespace :fp_growth do
    FP_GROWTH_DUMP_DIR = File.join(Rake.application.original_dir, 'tmp/fp_growth.dump')

    desc 'Benchmark Diggit::Analysis::ChangePatterns::FpGrowth'
    task :benchmark, BENCHMARK_TASK_ARGS do |_, args|
      require 'diggit/analysis/change_patterns/fp_growth'
      benchmark_fp_discovery(Diggit::Analysis::ChangePatterns::FpGrowth,
                             args, FP_GROWTH_DUMP_DIR)
    end
  end

  namespace :apriori do
    APRIORI_DUMP_DIR = File.join(Rake.application.original_dir, 'tmp/apriori.dump')

    desc 'Benchmark Diggit::Analysis::ChangePatterns::Apriori'
    task :benchmark, BENCHMARK_TASK_ARGS do |_, args|
      require 'diggit/analysis/change_patterns/apriori'
      benchmark_fp_discovery(Diggit::Analysis::ChangePatterns::Apriori,
                             args, APRIORI_DUMP_DIR)
    end
  end
end
