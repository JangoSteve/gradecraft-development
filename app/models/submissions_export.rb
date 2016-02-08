class SubmissionsExport < ActiveRecord::Base
  belongs_to :course
  belongs_to :professor, class_name: "User", foreign_key: "professor_id"
  belongs_to :team
  belongs_to :assignment

  attr_accessible :course_id, :professor_id, :team_id, :assignment_id, :submissions_snapshot,
    :s3_object_key, :export_filename, :s3_bucket, :last_export_started_at, :last_export_completed_at,
    :student_ids, :performer_error_log,
    :generate_export_csv,
    :create_student_directories,
    :student_directories_created_successfully,
    :create_submission_text_files,
    :create_submission_binary_files,
    :remove_empty_student_directories,
    :generate_error_log,
    :archive_exported_files,
    :upload_archive_to_s3,
    :check_s3_upload_success,
    :confirm_export_csv_integrity,
    :write_note_for_missing_binary_files

  validates :course_id, presence: true
  validates :assignment_id, presence: true

  before_create :set_s3_bucket_name

  def build_s3_object_key(object_filename)
    if Rails.env.development?
      [ ENV['AWS_S3_DEVELOPER_TAG'] ].concat(s3_object_key_pieces(object_filename)).join("/")
    else
      s3_object_key_pieces(object_filename).join("/")
    end
  end

  def s3_object_key_pieces(object_filename)
    [
      "exports",
      "courses",
      course_id,
      "assignments",
      assignment_id,
      created_at_date,
      created_at_in_microseconds,
      object_filename
    ]
  end

  def presigned_s3_url
    if s3_object_key
      s3_manager.bucket.object(s3_object_key).presigned_url(:get, expires_in: 604800).to_s
    end
  end

  def created_at_in_microseconds
    created_at.to_f.to_s.gsub(".","")
  end

  def created_at_date
    created_at.strftime("%F")
  end

  def s3_manager
    @s3_manager ||= S3Manager::Manager.new
  end

  def downloadable?
    !! last_export_completed_at
  end

  def upload_file_to_s3(file_path)
    s3_manager.put_encrypted_object(s3_object_key, file_path)
  end

  def fetch_object_from_s3
    s3_manager.get_encrypted_object(s3_object_key)
  end

  def write_s3_object_to_file(target_file_path)
    s3_manager.write_encrypted_object_to_file(s3_object_key, target_file_path)
  end

  def delete_object_from_s3
    s3_manager.delete_object(s3_object_key)
  end

  def update_export_completed_time
    update_attributes last_export_completed_at: export_time
  end

  def set_s3_bucket_name
    self[:s3_bucket_name] = s3_manager.bucket_name
  end

  def s3_object_exists?
    s3_object_summary.exists?
  end

  def s3_object_summary
    @s3_object_summary ||= S3Manager::Manager::ObjectSummary.new(s3_object_key, s3_manager)
  end

  private

  def export_time
    Time.now
  end

  def s3_attributes
    {
      s3_bucket_name: s3_manager.bucket_name,
      s3_object_key: s3_object_key
    }
  end
end
