class ChallengeGradesController < ApplicationController

  before_filter :ensure_staff?, :except => [:show]

  def index
    @challenge = current_course.challenges.find(params[:challenge_id])
    redirect_to @challenge
  end

  def show
    @challenge = current_course.challenges.find(params[:challenge_id])
    @challenge_grade = @challenge.challenge_grades.find(params[:id])
    @team = @challenge_grade.team
    @title = "#{@team.name}'s #{@challenge_grade.name} Grade"
  end

  def new
    @challenge = current_course.challenges.find(params[:challenge_id])
    @team = current_course.teams.find(params[:team_id])
    @teams = current_course.teams
    @challenge_grade = @team.challenge_grades.new
    @title = "Grading #{@team.name}'s #{@challenge.name}"
  end

  def edit
    @challenge = current_course.challenges.find(params[:challenge_id])
    @title = "Editing #{@challenge.name} Grade"
    @teams = current_course.teams
    @challenge_grade = @challenge.challenge_grades.find(params[:id])
  end

  # Grade many teams on a particular challenge at once
  def mass_edit
    @challenge = current_course.challenges.find(params[:challenge_id])
    @teams = current_course.teams
    @title = "Quick Grade #{@challenge.name}"
    @challenge_score_levels = @challenge.challenge_score_levels
    @students = current_course.students
    @challenge_grades = @teams.map do |t|
      @challenge.challenge_grades.where(:team_id => t).first || @challenge.challenge_grades.new(:team => t, :challenge => @challenge)
    end
  end

  def mass_update
    @challenge = current_course.challenges.find(params[:id])
    if @challenge.update_attributes(params[:challenge])
      redirect_to challenge_path(@challenge), notice: "#{@challenge.name} #{term_for :challenge} successfully graded"
    else
      redirect_to mass_edit_challenge_challenge_grades_path(@challenge)
    end
  end


  def create
    @challenge = current_course.challenges.find(params[:challenge_id])
    @challenge_grade = @challenge.challenge_grades.create(params[:challenge_grade])
    respond_to do |format|
      if @challenge_grade.save
        if current_course.add_team_score_to_student?
          @team = @challenge_grade.team
          @team.students.each do |student|
            # @mz TODO: add specs
            ScoreRecalculatorJob.new(user_id: student.id, course_id: current_course.id).enqueue
          end
        end
        format.html { redirect_to @challenge, notice: "#{@challenge.name} #{term_for :challenge} successfully graded" }
        format.json { render json: @challenge, status: :created, location: @challenge_grade }
      else
        format.html { render action: "new" }
        format.json { render json: @challenge_grade.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    @challenge = current_course.challenges.find(params[:challenge_id])
    @challenge_grade = current_course.challenge_grades.find(params[:id])
    respond_to do |format|
      if @challenge_grade.update_attributes(params[:challenge_grade])
        scored_changed = @challenge_grade.previous_changes[:score].present?
        if current_course.add_team_score_to_student? && scored_changed
          @team = @challenge_grade.team
          @team.students.each do |student|
            # @mz TODO: add specs
            ScoreRecalculatorJob.new(user_id: student.id, course_id: current_course.id).enqueue
          end
        end
        format.html { redirect_to @challenge, notice: "Grade for #{@challenge.name} #{term_for :challenge} successfully updated" }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @challenge_grades.errors, status: :unprocessable_entity }
      end
    end
  end

  # Changing the status of a grade - allows instructors to review "Graded" grades, before they are "Released" to students
  def edit_status
    @challenge = current_course.challenges.find(params[:challenge_id])
    @title = "#{@challenge.name} Grade Statuses"
    @challenge_grades = @challenge.challenge_grades.find(params[:challenge_grade_ids])
  end

  def update_status
    @challenge = current_course.challenges.find(params[:challenge_id])
    @challenge_grades = @challenge.challenge_grades.find(params[:challenge_grade_ids])
    @challenge_grades.each do |challenge_grade|
      challenge_grade.update_attributes!(params[:challenge_grade].reject { |k,v| v.blank? })
    end
    flash[:notice] = "Updated Grades!"
    redirect_to challenge_path(@challenge)
  end

  def destroy
    @challenge_grade = current_course.challenge_grades.find(params[:id])
    @challenge = current_course.challenges.find(@challenge_grade.challenge_id)
    @challenge_grade.destroy

    respond_to do |format|
      format.html { redirect_to challenge_path(@challenge) }
      format.json { head :ok }
    end
  end

end
