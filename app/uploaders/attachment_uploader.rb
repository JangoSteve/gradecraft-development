class AttachmentUploader < CarrierWave::Uploader::Base
  include ::CarrierWave::Backgrounder::Delay

  # NOTE: course, assignment and assignment_file_type, and student should be defined on the model in order
  # to use them as subdirectories, otherwise they will be ommited:
  # submission_file: uploads/<course-name_id>/assignments/<assignment-name_id>/submission_files/<student_name>/timestamp_file_name.ext
  # assigment_file:  uploads/<course-name_id>/assignments/<assignment-name_id>/assignment_files/<timestamp_file-name.ext>
  # grade_file: uploads/<course-name_id>/assignments/<assignment-name_id>/grade_files/<timestamp_file-name.ext>
  # badge_file: uploads/<course-name_id>/badge_files/<timestamp_file-name.ext>
  # challenge_file: uploads/<course-name_id>/challenge_files/<timestamp_file-name.ext>
  #
  def store_dir
    course = "/#{model.course.courseno}-#{model.course.id}" if model.class.method_defined? :course
    assignment =  "/assignments/#{model.assignment.name.gsub(/\s/, "_").downcase[0..20]}-#{model.assignment.id}" if model.class.method_defined? :assignment
    file_type = "/#{model.class.to_s.underscore.pluralize}"
    owner = "/#{model.owner_name}" if model.class.method_defined? :owner_name
    "uploads#{course}#{assignment}#{file_type}#{owner}"

    if Rails.env.development?
      [ "uploads", ENV['AWS_S3_DEVELOPER_TAG'], course, assignment, file_type, owner ].compact.join("/")
    else
      [ "uploads", course, assignment, file_type, owner ].compact.join("/")
    end
  end

  # Override the filename of the uploaded files:
  def filename
    if original_filename.present?
      if model && model.read_attribute(mounted_as).present?
        model.read_attribute(mounted_as)
      else
        "#{tokenized_name}.#{file.extension}"
      end
    end
  end

  private

  def course
    "#{model.course.courseno}-#{model.course.id}" if model.class.method_defined? :course
  end

  def assignment
    "assignments/#{model.assignment.name.gsub(/\s/, "_").downcase[0..20]}-#{model.assignment.id}" if model.class.method_defined? :assignment
  end

  def file_type
    model.class.to_s.underscore.pluralize
  end

  def owner
    model.owner_name.gsub(/\s/, "-") if model.class.method_defined? :owner_name
  end

  def tokenized_name
    model.instance_variable_get(secure_token_name) || model.instance_variable_set(secure_token_name, filename_from_basename)
  end

  def filename_from_basename
    "#{Time.now.to_i}_#{file.basename.gsub(/\W+/, "_").downcase[0..40]}"
  end

  def secure_token_name
    :"@#{mounted_as}_secure_token"
  end
end
