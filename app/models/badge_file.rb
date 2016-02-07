class BadgeFile < ActiveRecord::Base
  include S3Manager::Carrierwave

  attr_accessible :file, :filename, :filepath, :badge_id

  belongs_to :badge

  validates :filename, presence: true, length: { maximum: 50 }

  mount_uploader :file, AttachmentUploader
  process_in_background :file

  def course
    badge.course
  end
end
