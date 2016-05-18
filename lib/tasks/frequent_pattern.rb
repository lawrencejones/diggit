# rubocop:disable Lint/Debugger, Metrics/AbcSize, Metrics/MethodLength
namespace :frequent_pattern do
  RAILS_CHANGESETS_FILE = File.join(Rake.application.original_dir,
                                    'tmp/rails_changesets.yaml')

  desc 'Generate rails changesets'
  task :generate_changesets, [:rails_path] do |_, args|
    if File.exist?(RAILS_CHANGESETS_FILE)
      puts('Found existing changesets file!')
      next
    end

    require 'rugged'
    puts('Loading rails repo...')
    rails_path = File.join(Rake.application.original_dir, args.fetch(:rails_path))
    rails = Rugged::Repository.new(rails_path)

    walker = Rugged::Walker.new(rails)
    walker.sorting(Rugged::SORT_DATE)
    walker.push(rails.last_commit)

    puts('Walking commit history...')
    transactions = walker.map do |commit|
      files_changed = commit.diff(commit.parents.first).deltas.map do |delta|
        delta.new_file[:path]
      end
      [commit.oid, files_changed.sort]
    end.to_h

    puts("Discovered #{transactions.count} changesets!")
    puts("Writing changesets to #{RAILS_CHANGESETS_FILE}...")
    File.write(RAILS_CHANGESETS_FILE, transactions.to_yaml)

    puts('Done!')
  end

  # Runs and profiles blocks that generate frequent pattern sets from the rails
  # changesets.
  def benchmark_fp_discovery(algorithm, args, dump_dir)
    require 'yaml'
    require 'ruby-prof'
    require 'fileutils'

    count = args.fetch(:count, 10_000).to_i
    min_support = args.fetch(:min_support, 10).to_i
    puts('Loading rails changesets...')
    changesets = YAML.load_file(RAILS_CHANGESETS_FILE).first(count).map(&:second)

    profile = patterns = nil

    puts('Beginning benchmark...')
    run_time = Benchmark.measure do
      profile = RubyProf.profile do
        patterns = algorithm.new(changesets,
                                 min_support: min_support,
                                 max_items: 10).frequent_itemsets
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

    RubyProf::MultiPrinter.new(profile).print(path: dump_dir, profile: 'profile')
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
    task :benchmark, [:count, :min_support] do |_, args|
      require_relative '../diggit/analysis/change_patterns/fp_growth'
      benchmark_fp_discovery(Diggit::Analysis::ChangePatterns::FpGrowth,
                             args, FP_GROWTH_DUMP_DIR)
    end
  end

  namespace :apriori do
    APRIORI_DUMP_DIR = File.join(Rake.application.original_dir, 'tmp/apriori.dump')

    desc 'Benchmark Diggit::Analysis::ChangePatterns::Apriori'
    task :benchmark, [:count, :min_support] do |_, args|
      require_relative '../diggit/analysis/change_patterns/apriori'
      benchmark_fp_discovery(Diggit::Analysis::ChangePatterns::Apriori,
                             args, FP_GROWTH_DUMP_DIR)
    end
  end
end
