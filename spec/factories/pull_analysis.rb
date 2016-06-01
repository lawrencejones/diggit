require_relative '../../lib/diggit/analysis/pipeline'

FactoryGirl.define do
  factory :pull_analysis do
    sequence(:pull)
    comments [{ 'message' => 'bazinga!' }]
    sequence(:head) { |n| "head-sha-#{n}" }
    base 'base-sha'
    pushed_to_github false
    duration { (3 * Random.rand)**2 }
    reporters Diggit::Analysis::Pipeline.reporters
    project
  end
end
