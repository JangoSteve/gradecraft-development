class CoursesController < ApplicationController

  before_filter :ensure_staff?, :except => [:timeline]

  def index
    @title = "Course Index"
    @courses = Course.all
  end

  def show
    @title = "Course Settings"
    @course = Course.find(params[:id])
  end

  def new
    @title = "Create a New Course"
    @course = Course.new
  end

  def edit
    @title = "Editing Basic Settings"
    @course = Course.find(params[:id])
  end

  # Important for instructors to be able to copy one course's structure into a new one - does not copy students or grades
  def copy
    @course = Course.find(params[:id])
    new_course = @course.dup
    new_course.name.prepend("Copy of ")
    new_course.save
    if @course.badges.present?
      @course.badges.each do |b|
        nb = b.dup
        nb.course_id = new_course.id
        nb.save
      end
    end
    if @course.assignment_types.present?
      @course.assignment_types.each do |at|
        nat = at.dup
        nat.course_id = new_course.id
        nat.save
        at.assignments.each do |a|
          na = a.dup
          na.assignment_type_id = nat.id
          na.course_id = new_course.id
          na.save
          if a.assignment_score_levels.present?
            a.assignment_score_levels.each do |asl|
              nasl = asl.dup
              nasl.assignment_id = na.id
              nasl.save
            end
          end
          if a.rubric.present?
            new_rubric = a.rubric.dup
            new_rubric.assignment_id = na.id
            new_rubric.save
            if a.rubric.metrics.present?
              a.rubric.metrics.each do |metric|
                new_metric = metric.dup
                new_metric.rubric_id = new_rubric.id
                new_metric.add_default_tiers = false
                new_metric.save
                if metric.tiers.present?
                  metric.tiers.each do |tier|
                    new_tier = tier.dup
                    new_tier.metric_id = new_metric.id
                    new_tier.save
                    if tier.tier_badges.present?
                      tier.tier_badges.each do |tier_badge|
                        new_tier_badge = tier_badge.dup
                        new_tier_badge.tier_id = new_tier.id
                        new_tier_badge.save
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
    if @course.challenges.present?
      @course.challenges.each do |c|
        nc = c.dup
        nc.course_id = new_course.id
        nc.save
      end
    end
    if @course.grade_scheme_elements.present?
      @course.grade_scheme_elements.each do |gse|
        ngse = gse.dup
        ngse.course_id = new_course.id
        ngse.save
      end
    end
    respond_to do |format|
      if new_course.save
        new_course.course_memberships.create(:user_id => current_user.id, :role => current_user.course_memberships.where(:course_id => current_course.id).first.role)
        session[:course_id] = new_course.id
        format.html { redirect_to course_path(@course), notice: "#{@course.name} successfully copied" }
      else
        redirect_to courses_path, alert: "#{@course.name} was not successfully copied"
        format.json { render json: @course.errors, status: :unprocessable_entity }
      end
    end

  end

  def create
    @course = Course.new(params[:course])
    @title = "Create a New Course"

    respond_to do |format|
      if @course.save
        @course.course_memberships.create(:user_id => current_user.id, :role => current_user.course_memberships.where(:course_id => current_course.id).first.role, instructor_of_record: true)
        session[:course_id] = @course.id
        format.html { redirect_to course_path(@course), notice: "Course #{@course.name} successfully created" }
        format.json { render json: @course, status: :created, location: @course }
      else
        format.html { render action: "new" }
        format.json { render json: @course.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    @course = Course.find(params[:id])
    @title = "Editing Basic Settings"

    respond_to do |format|
      if @course.update_attributes(params[:course])
        format.html { redirect_to @course, notice: "Course #{@course.name} successfully updated" }
      else
        redirect_to edit_course_path
      end
    end
  end

  def timeline_settings
    @course = current_course
    @assignments = current_course.assignments.includes(:assignment_type)
    @title = "Timeline Settings"
  end

  def timeline_settings_update
    @course = current_course
    if @course.update_attributes(params[:course])
      redirect_to dashboard_path
    else
      redirect_to timeline_settings_path, :course => @course
    end
  end

  def predictor_settings
    @course = current_course
    @assignments = current_course.assignments.includes(:assignment_type)
    @title = "Grade Predictor Settings"
  end

  def predictor_settings_update
    @course = current_course
    if @course.update_attributes(params[:course])
      respond_with @course
    else
      redirect_to predictor_settings_path, :course => @course
    end
  end

  def predictor_preview
    @assignments = current_course.assignments
    @grade_scheme_elements = current_course.grade_scheme_elements
    @grade_levels_json = @grade_scheme_elements.order(:low_range).pluck(:low_range, :letter, :level).to_json
  end

  def destroy
    @course = Course.find(params[:id])
    @name = @course.name
    @course.destroy

    respond_to do |format|
      format.html { redirect_to courses_url, notice: "Course #{@name} successfully deleted" }
      format.json { head :no_content }
    end
  end

  def assignments
    @course = current_course
    @assignments = EventSearch.new(:current_user => current_user, :events => @course.events).find
    respond_with @assignments do |format|
      format.ics do
        render :text => CalendarBuilder.new(:assignments => @assignments).to_ics, :content_type => 'text/calendar'
      end
    end
  end

  def export_earned_badges
    @course = current_course
    respond_to do |format|
      format.csv { send_data @course.earned_badges_for_course }
    end
  end

  # Exporting student grades
  def export_student_grades
    @students = current_course.students_being_graded respond_to do |format|
      format.json { render json: @students.where("first_name like ?", "%#{params[:q]}%") }
      format.csv { send_data @students.csv_for_course(current_course) }
    end
  end

end
