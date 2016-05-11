require_relative '../diggit/system'
Diggit::System.init

namespace :one_off do
  desc 'Adds a private repo to be polled'
  task :add_polled_repo, [:gh_path] do |_, args|
    if Project.exists?(gh_path: args[:gh_path])
      puts("Project #{args[:gh_path]} is already watched!")
    end

    puts("Adding repo #{args[:gh_path]}...")
    project = ActiveRecord::Base.transaction do
      Project.
        create!(gh_path: args[:gh_path],
                watch: true,
                polled: true).
        tap(&:generate_keypair!)
    end
    puts('Done!')
    puts('Add the following public key to Github account with access to this repo:')
    puts("\n#{project.ssh_public_key}\n")
  end

  desc 'Backfills projects to use diggit-bot github token'
  task :backfill_projects_gh_token do
    puts("Backfilling #{Project.count} projects...")
    ActiveRecord::Base.transaction do
      Project.all.each do |project|
        puts("- #{project.gh_path}")
        project.gh_token = Prius.get(:diggit_github_token)
        project.save!
      end
    end
    puts('Done!')
  end
end
