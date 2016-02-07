class ChallengeFile < ActiveRecord::Base
  include S3Manager::Carrierwave

  attr_accessible :file, :filename, :filepath, :challenge_id

  belongs_to :challenge

  validates :filename, presence: true, length: { maximum: 50 }

  mount_uploader :file, AttachmentUploader
  process_in_background :file
end
