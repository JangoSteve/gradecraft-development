FactoryGirl.define do
  factory :course do
    name { Faker::Internet.domain_word }
    courseno { Faker::Internet.domain_word }
    semester 'Fall'
    badge_setting false
    use_timeline true

    factory :course_accepting_groups do
      min_group_size 2
      max_group_size 10
    end

    factory :course_with_weighting do
      total_assignment_weight 6
      max_assignment_weight 4
      max_assignment_types_weighted 2
      default_assignment_weight 3
    end

    factory :course_without_timeline do 
      use_timeline false
    end

    factory :invalid_course do
      name nil
    end
    
  end

end
