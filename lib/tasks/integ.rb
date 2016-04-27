namespace :integ do
  desc 'Fire webhook fixture at localhost:9292'
  task :trigger_webhook, [:fixture, :host] do |_, args|
    fixture_file = "#{args[:fixture]}.fixture.json"
    fixture_path = File.join(Rake.application.original_dir,
                             'spec/fixtures/api/github_webhooks', fixture_file)

    fail "Fixture #{fixture_file} does not exist!" unless File.exist?(fixture_path)

    system %(
    curl -X POST \
         -H 'User-Agent: GitHub-Hookshot/cd33156' \
         -H 'X-GitHub-Delivery: d2c29011-0ce5-12e6-91f7-f1a20178506c' \
         -H 'X-GitHub-Event: pull_request' \
         -H 'Content-Type: application/json' \
         -H 'Accept: application/json' \
         -d @'#{fixture_path}' \
         #{args.fetch(:host, 'http://localhost:9292')}/api/github_webhooks)
  end
end
