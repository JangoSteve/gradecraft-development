json.challenges @challenges do |challenge|
  json.merge! challenge.attributes
  json.info ! challenge.description.blank?
  json.score_levels challenge.challenge_score_levels.map {|csl| {name: csl.name, value: csl.value}}

  challenge.student_predicted_earned_challenge.tap do |prediction|
    cache ["v1", prediction] do
      json.prediction do
        if current_user.is_staff?(current_course)
          prediction.points_earned = 0
        end

        json.merge! prediction.attributes
      end
    end
  end

  challenge.current_team_grade.tap do |grade|
    cache ["v1", grade] do
      json.grade do
        json.id grade.id
        json.challenge_id grade.challenge_id
        json.score grade.score
        json.status grade.status
        json.team_id grade.team_id
        json.final_score grade.final_score
        # work like the assignments structure: assignment.grade.point_total
        json.point_total challenge.point_total
      end
    end
  end
end

json.term_for_challenges term_for :challenges
