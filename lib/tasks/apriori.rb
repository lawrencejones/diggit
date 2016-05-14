require_relative '../diggit/analysis/change_patterns/apriori'

namespace :apriori do
  BENCHMARK_DUMP_FILE = File.join(Rake.application.original_dir, 'tmp/apriori.dump')
  RAILS_CHANGESETS_FILE = File.join(Rake.application.original_dir,
                                    'tmp/rails_changesets.yaml')

  desc 'Benchmarks Diggit::Analysis::ChangePatterns::Apriori'
  task :benchmark, [:count] do |_, args|
    require 'yaml'
    require 'stackprof'

    count = args.fetch(:count, 5000)
    puts('Loading rails changesets...')
    changesets = YAML.load_file(RAILS_CHANGESETS_FILE)

    puts("Selecting first #{count} changesets...")
    changesets = changesets.first(count).to_h

    puts('Beginning benchmark...')
    run_time = Benchmark.measure do
      StackProf.run(mode: :cpu, out: BENCHMARK_DUMP_FILE) do
        apriori = Diggit::Analysis::ChangePatterns::Apriori.
          new(changesets, min_support: 30)
        apriori.apriori_tid
      end
    end
    puts(run_time)
    puts("Saved dump to #{BENCHMARK_DUMP_FILE}")
  end

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
end
