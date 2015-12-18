GradeCraft::Application.routes.draw do

  mount RailsEmailPreview::Engine, at: 'emails' if Rails.env.development?

  require 'admin_constraint'

  #1. Analytics & Charts
  #2. Announcements
  #3. Assignments, Submissions, Tasks, Grades
  #4. Assignment Types
  #5. Assignment Type Weights
  #6. Badges
  #7. Challenges
  #8. Courses
  #9. Groups
  #10. Informational Pages
  #11. Rubrics & Grade Schemes
  #12. Teams
  #13. Users
  #14. User Auth
  #15. Uploads
  #16. Events
  #17. Predictor
  #18. Exports

  #1. Analytics & Charts
  namespace :analytics do
    root action: :index
    get :staff
    get :students
    get :all_events
    get :role_events
    get :assignment_events
    get :login_frequencies
    get :role_login_frequencies
    get :login_events
    get :login_role_events
    get :all_pageview_events
    get :all_role_pageview_events
    get :all_user_pageview_events
    get :pageview_events
    get :role_pageview_events
    get :user_pageview_events
    get :prediction_averages
    get :assignment_prediction_averages
    get :export
  end

  post 'analytics_events/predictor_event'
  post 'analytics_events/tab_select_event'

  #2. Announcements
  resources :announcements, except: [:destroy, :edit, :update]

  #3. Assignments, Submissions, Tasks, Grades
  resources :assignments do
    collection do
      post :sort
      get :feed
      get :settings
      post 'copy' => 'assignments#copy'
      get 'export_structure'
      get 'weights' => 'assignment_weights#mass_edit', :as => :mass_edit_weights
    end
    member do
      get 'mass_grade' => 'grades#mass_edit', as: :mass_grade
      put 'mass_grade' => 'grades#mass_update'
      get 'group_grade' => 'grades#group_edit', as: :group_grade
      put 'group_grade' => 'grades#group_update'
      get 'export_grades'
      get 'export_submissions'
      get 'download_current_grades' => 'assignments#download_current_grades'
      get 'criterion_grades_review'
      get 'export_team_submissions'
      get 'submissions_export', defaults: {format: :json}
      get 'export_team_submissions'
      get 'grade_import' => 'assignments#grade_import'
      get 'rubric_grades_review'
      put :update_rubrics
      scope 'grades', as: :grades, controller: :grades do
        get :edit_status
        put :update_status
        get :import
        post :upload
        post :self_log
        post :predict_score
        post :feedback_read
        post :remove
      end
    end
    resources :submissions, except: :index do
      post :upload
    end
    resources :tasks
    resource :grade, only: [:show, :edit, :update, :destroy] do
      put :submit_rubric, on: :collection
      resources :earned_badges
    end
    resource :rubric do
      get :existing_criteria
      resources :criteria
      get :design, on: :collection
    end
  end
  resources :unlock_states do
    member do
      post :manually_unlock
    end
  end
  resources :unlock_conditions


  # earned badges grade routes
  put "grades/:id/async_update", to: "grades#async_update"
  post "grades/earn_student_badge", to: "grades#earn_student_badge"
  post "grade/:grade_id/earn_student_badges", to: "grades#earn_student_badges"
  delete "grade/:grade_id/student/:student_id/badge/:badge_id/earned_badge/:id", to: "grades#delete_earned_badge"
  delete "grade/:grade_id/earned_badges", to: "grades#delete_all_earned_badges"

  resources :criteria do
    put :update_order, on: :collection
  end

  resources :levels
  resources :graded_criteria

  resources :level_badges

  #4. Assignment Types
  resources :assignment_types do
    member do
      get 'all_grades'
      get 'export_scores'
    end
    collection do
      post :sort
      get 'export_all_scores'
    end
  end

  #5. Assignment Type Weights
  get 'assignment_type_weights' => 'assignment_type_weights#mass_edit', as: :assignment_type_weights
  put 'assignment_type_weights' => 'assignment_type_weights#mass_update'
  post 'assignment_type_weight' => 'assignment_type_weights#update'

  resources :assignment_weights

  #6. Badges
  resources :badges do
    post :predict_times_earned
    resources :tasks
    resources :earned_badges
    member do
      get 'mass_award' => 'earned_badges#mass_edit', as: :mass_award
      post 'mass_earn' => 'earned_badges#mass_earn'
    end
    collection do
      post :sort
    end
  end

  #7. Challenges
  resources :challenges do
    post :predict_points
    resources :challenge_grades do
      collection do
        post :edit_status
        put :update_status
        get :mass_edit

      end
    end
    member do
      get 'mass_edit' => 'challenge_grades#mass_edit', as: :mass_edit
      put 'mass_edit' => 'challenge_grades#mass_update'
    end
    resources :challenge_files do
      get :remove
    end
  end

  #8. Courses
  resources :courses do
    collection do
      post 'copy' => 'courses#copy'
    end
    member do
      get 'timeline_settings' => 'courses#timeline_settings'
      put 'timeline_settings' => 'courses#timeline_settings_update'
      get 'predictor_settings' => 'courses#predictor_settings', as: :predictor_settings
      put 'predictor_settings' => 'courses#predictor_settings_update'
#      get 'predictor_preview' => 'courses#predictor_preview'
    end
  end
  resources :course_memberships

  post '/current_course/change' => 'current_courses#change', :as => :change_current_course
  get 'current_course' => 'current_courses#show'

  get 'leaderboard' => 'students#leaderboard'
  get 'multiplier_choices' => 'info#choices'
  get 'earned_badges' => 'info#awarded_badges'
  get 'grading_status' => 'info#grading_status'
  get 'resubmissions' => 'info#resubmissions'
  get 'ungraded_submissions' => 'info#ungraded_submissions'
  get 'top_10' => 'info#top_10'
  get 'per_assign' => 'info#per_assign'
  get 'gradebook' => 'info#gradebook'
  get 'multiplied_gradebook' => 'info#multiplied_gradebook'
  get 'final_grades' => 'info#final_grades'
  get 'research_gradebook' => 'info#research_gradebook'
  get 'export_earned_badges' => 'courses#export_earned_badges'

  #9. Groups
  resources :groups do
    resources :proposals
  end
  resources :group_memberships

  #10. Informational Pages
  namespace :info do
    get :choices
    get :awarded_badges
    get :dashboard
    get :grading_status
    get :timeline_events
    get :resubmissions
    get :top_10
    get :per_assign
  end

  resources :home

  get 'um_pilot' => 'pages#um_pilot'
  get 'features' => 'pages#features'
  get 'press' => 'pages#press'
  get 'research' => 'pages#research'
  get 'our_team' => 'pages#team'

  #11. Rubrics & Grade Schemes
  resources :rubrics

  #11. Rubrics & Grade Schemes
  resources :grade_scheme_elements do
    collection do
      post :destroy_multiple
      get 'mass_edit' => 'grade_scheme_elements#mass_edit', as: :mass_edit
      put 'mass_edit' => 'grade_scheme_elements#mass_update'
    end
  end

  #12. Teams
  resources :teams do
    collection do
      get :activity
    end
    resources :earned_badges
  end

  get 'home' => 'pages#home'
  get 'dashboard' => 'info#dashboard'
  get 'brand_and_style' => 'pages#brand_and_style_guidelines'
  root :to => "pages#home"

  #13. Users
  %w{students gsis professors admins}.each do |role|
    get "users/#{role}/new" => 'users#new', :as => "new_#{role.singularize}", :role => role.singularize
  end

  resources :users do
    get :activate, on: :member
    post :activate, on: :member, action: :activated
    post :flag, on: :member
    collection do
      get :edit_profile
      put :update_profile
      get :import
      post :upload
    end
  end
  resources :students do
    get :grade_index
    get :timeline
    get :syllabus
    get :badges
    get :predictor
    get :course_progress
    get :teams
    get :recalculate
    resources :student_academic_histories
    collection do
      get :leaderboard
      get :choices
      get :autocomplete_student_name
      get :scores_for_current_course
      get :scores_by_assignment
      get :scores_by_team
      get :scores_for_single_assignment
      get :final_grades
      get :class_badges
      get :flagged
    end
  end
  resources :staff, only: [:index, :show]
  resources :user_sessions
  resources :passwords, path_names: { new: 'reset' }, except: [:destroy, :index]

  get 'timeline' => 'students#timeline'
  get 'syllabus' => 'students#syllabus'
  get 'course_progress' => 'students#course_progress'
  get 'my_badges' => 'students#badges'
  get 'my_team' => 'students#teams'

  #14. User Auth
  post 'auth/lti/callback', to: 'user_sessions#lti_create'
  get 'auth/failure' => 'pages#auth_failure', as: :auth_failure

  get 'login' => 'user_sessions#new', :as => :login
  get 'logout' => 'user_sessions#destroy', :as => :logout
  get 'reset' => 'user_sessions#new'

  #SAML
  get 'saml/init'
  post 'saml/consume'
  get 'saml/metadata'
  get 'saml/logout'

  get 'lti/:provider/launch', to: 'lti#launch', :as => :launch_lti_provider

  #15. Uploads
  resource :uploads do
    get :remove
    get :stuff
    get :remove_submission_file
  end

  #16. Events
  resources :events

  #17. API Calls

  get 'gse_mass_edit' => 'grade_scheme_elements#mass_edit', defaults: { format: :json }

  #17.a Rubric Calls
  namespace :api do
    get 'assignments/:id/criteria', to: 'criteria#index', defaults: { format: :json }
    get 'assignments/:id/students/:student_id/grade', to: 'grades#show', defaults: { format: :json }
    resources :badges, only: :index, defaults: { format: :json }

  end

  #17b. Predictor, Student View
  get 'predictor' => 'students#predictor'
  get 'predictor_grade_levels' => 'grade_scheme_elements#predictor_data', defaults: { format: :json }
  get 'predictor_assignment_types' => 'assignment_types#predictor_data', defaults: { format: :json }
  get 'predictor_assignments' => 'assignments#predictor_data', defaults: { format: :json }
  get 'predictor_badges' => 'badges#predictor_data', defaults: { format: :json }
  get 'predictor_challenges' => 'challenges#predictor_data', defaults: { format: :json }
  get 'predictor_weights' => 'assignment_type_weights#predictor_data', defaults: { format: :json }

  #17c. Predictor, Instructor View
  get 'students/:id/predictor_grade_levels' => 'grade_scheme_elements#predictor_data', defaults: { format: :json }
  get 'students/:id/predictor_assignment_types' => 'assignment_types#predictor_data', defaults: { format: :json }
  get 'students/:id/predictor_assignments' => 'assignments#predictor_data', defaults: { format: :json }
  get 'students/:id/predictor_badges' => 'badges#predictor_data', defaults: { format: :json }
  get 'students/:id/predictor_challenges' => 'challenges#predictor_data', defaults: { format: :json }
  get 'students/:id/predictor_weights' => 'assignment_type_weights#predictor_data', defaults: { format: :json }

  #18. Exports
  resources :exports
  get 'exports_controller/index'

  resources :submissions_exports do
    member do
      get :download
    end
  end
end

