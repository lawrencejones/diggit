FactoryGirl.define do
  factory :project do
    sequence(:gh_path) { |n| "lawrencejones/#{n}" }
    watch false
    silent false

    trait :watched do
      watch true
    end

    trait :deploy_keys do
      ssh_public_key 'ssh-public-key'
      ssh_private_key 'ssh-private-key'
    end

    trait :gh_token do
      gh_token 'github-token'
    end

    trait :diggit do
      watched
      gh_path 'lawrencejones/diggit'
    end
  end
end
