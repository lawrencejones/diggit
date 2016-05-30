# rubocop:disable Lint/Debugger, Metrics/AbcSize, Metrics/MethodLength
namespace :frequent_pattern do
  # Runs and profiles blocks that generate frequent pattern sets from the rails
  # changesets.
  def benchmark_fp_discovery(algorithm, args, dump_dir)
    require 'yaml'
    require 'ruby-prof'
    require 'fileutils'

    require 'diggit/analysis/change_patterns/changeset_generator'

    min_support = args.fetch(:min_support, 10).to_i
    max_items = args.fetch(:max_items, 20).to_i

    puts('Loading rails repo...')
    rails_path = File.join(Rake.application.original_dir, args.fetch(:rails_path))
    rails = Rugged::Repository.new(rails_path)

    puts('Walking commit history...')
    changesets = Diggit::Analysis::ChangePatterns::ChangesetGenerator.
      new(rails, gh_path: 'frequent_pattern/rails').changesets.first(10_000)
    puts("Loaded #{changesets.count} changesets!")

    profile = patterns = nil

    puts("Beginning benchmark #{{ min_support: min_support, max_items: max_items }}...")
    run_time = Benchmark.measure do
      profile = RubyProf.profile do
        patterns = algorithm.new(changesets,
                                 min_support: min_support,
                                 max_items: max_items).frequent_itemsets
      end
    end
    puts('Finished!')
    puts(run_time)

    FileUtils.rm_rf(dump_dir)
    FileUtils.mkdir_p(dump_dir)

    sorted_patterns = patterns.
      map { |itemset| itemset.merge(items: itemset[:items].to_a.sort) }.
      sort_by { |itemset| itemset[:items].join }
    File.write(File.join(dump_dir, 'results.json'), JSON.pretty_generate(sorted_patterns))
    puts("Written results to #{dump_dir}/results.json")

    # RubyProf::MultiPrinter.new(profile).print(path: dump_dir, profile: 'profile')
    puts("Saved dump to #{dump_dir}")

    print('Inspect patterns? [y/n]: ')
    if STDIN.gets.chomp[/y(es)?/]
      require 'pry'
      binding.pry
      patterns
    end

    puts('Done!')
  end

  namespace :fp_growth do
    FP_GROWTH_DUMP_DIR = File.join(Rake.application.original_dir, 'tmp/fp_growth.dump')

    desc 'Benchmark Diggit::Analysis::ChangePatterns::FpGrowth'
    task :benchmark, [:rails_path, :min_support] do |_, args|
      require 'diggit/analysis/change_patterns/fp_growth'
      benchmark_fp_discovery(Diggit::Analysis::ChangePatterns::FpGrowth,
                             args, FP_GROWTH_DUMP_DIR)
    end
  end

  namespace :apriori do
    APRIORI_DUMP_DIR = File.join(Rake.application.original_dir, 'tmp/apriori.dump')

    desc 'Benchmark Diggit::Analysis::ChangePatterns::Apriori'
    task :benchmark, [:rails_path, :min_support] do |_, args|
      require 'diggit/analysis/change_patterns/apriori'
      benchmark_fp_discovery(Diggit::Analysis::ChangePatterns::Apriori,
                             args, FP_GROWTH_DUMP_DIR)
    end
  end
end
