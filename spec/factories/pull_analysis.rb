FactoryGirl.define do
  factory :pull_analysis do
    sequence(:pull)
    comments [{ 'message' => 'bazinga!' }]
    head 'head-sha'
    base 'base-sha'
    pushed_to_github false
    duration { (3 * Random.rand)**2 }
    project
  end
end
