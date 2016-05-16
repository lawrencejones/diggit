require_relative '../diggit/analysis/change_patterns/apriori'

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

  namespace :apriori do
    APRIORI_DUMP_DIR = File.join(Rake.application.original_dir, 'tmp/apriori.dump')

    desc 'Benchmarks Diggit::Analysis::ChangePatterns::Apriori'
    task :benchmark, [:count, :min_support] do |_, args|
      require 'yaml'
      require 'ruby-prof'
      require 'fileutils'

      count = args.fetch(:count, 10_000).to_i
      min_support = args.fetch(:min_support, 10).to_i
      puts('Loading rails changesets...')
      changesets = YAML.load_file(RAILS_CHANGESETS_FILE).first(count)

      patterns = nil

      puts('Beginning benchmark...')
      run_time = Benchmark.measure do
        profile = RubyProf.profile do
          apriori = Diggit::Analysis::ChangePatterns::Apriori.
            new(changesets, min_support: min_support)
          patterns = apriori.apriori_tid
        end
        RubyProf::FlatPrinter.new(profile).print
        FileUtils.rm_rf(APRIORI_DUMP_DIR)
        FileUtils.mkdir_p(APRIORI_DUMP_DIR)
        RubyProf::MultiPrinter.new(profile).
          print(path: APRIORI_DUMP_DIR, profile: 'profile')
      end
      puts(run_time)
      puts("Saved dump to #{APRIORI_DUMP_DIR}")

      print('Inspect patterns? [y/n]: ')
      if STDIN.gets.chomp[/y(es)?/]
        # rubocop:disable Lint/Debugger
        require 'pry'
        binding.pry
        patterns
        # rubocop:enable Lint/Debugger
      end

      puts('Done!')
    end
  end
end
