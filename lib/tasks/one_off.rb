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
end
