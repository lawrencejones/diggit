require_relative '../diggit/system'
Diggit::System.init

namespace :one_off do
  task :backfill_pull_analyses do
    Diggit.logger.info("Backfilling #{PullAnalysis.count} pull analyses...")
    ActiveRecord::Base.transaction do
      PullAnalysis.all.each do |pull_analysis|
        pull = Diggit::Github.client.pull(pull_analysis.project.gh_path,
                                          pull_analysis.pull)
        pull_analysis.update(base: pull.base.sha, head: pull.head.sha)
        Diggit.logger.
          info("[#{pull_analysis.project.gh_path}##{pull_analysis.pull}] Updated!")
      end
    end
    Diggit.logger.info('Backfill done!')
  end
end
