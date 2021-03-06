FactoryGirl.define do
  factory :challenge_grade do
    association :challenge
    association :team

    factory :graded_challenge_grade do
      association :challenge
      association :team
      # TODO this should change to points_earned on the model
      score { rand(challenge.point_total) }
      status "Graded"
    end

    factory :grades_not_released_challenge_grade do
      association :challenge, release_necessary: true
      association :team
      # TODO this should change to points_earned on the model
      score { rand(challenge.point_total) }
      status "Graded"
    end
  end
end
