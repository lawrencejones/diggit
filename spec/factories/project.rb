FactoryGirl.define do
  factory :project do
    sequence(:gh_path) { |n| "lawrencejones/#{n}" }
    watch false

    trait :watched do
      watch true
      ssh_public_key 'ssh-public-key'
      ssh_private_key 'ssh-private-key'
    end

    trait :diggit do
      watched
      gh_path 'lawrencejones/diggit'
    end
  end
end
