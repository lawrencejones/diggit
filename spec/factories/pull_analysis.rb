FactoryGirl.define do
  factory :pull_analysis do
    sequence(:pull)
    comments [{'message' => 'bazinga!'}]
    project
  end
end
