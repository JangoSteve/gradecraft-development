# Meant for inclusion in ActiveRecord files that are persisting CarrierWave objects via S3
module S3Manager
  module Carrierwave
    extend ActiveSupport::Concern

    # Legacy submission files were handled by S3 direct upload and we stored their
    # Amazon key in the "filepath" field. Here we check if it has a value, and if
    # so we use this to retrieve our secure url. If not, we use the path supplied by
    # the carrierwave uploader

    attr_accessor :process_file_upload, :store_dir

    included do
      before_create :cache_store_dir
    end

    include S3Manager::Basics

    def url
      if s3_object
        s3_object.presigned_url(:get, expires_in: 900).to_s
      end
    end

    def s3_object
      bucket.object(s3_object_file_key)
    end

    def delete_from_s3
      s3_object.delete
    end

    def exists_on_s3?
      s3_object.exists?
    end

    def s3_object_file_key
      if cached_file_path
        cached_file_path # build a full file path from cached #store_dir and #filename attributes on the FooFile record
      elsif filepath.present?
        CGI::unescape(filepath)
      else
        file.path
      end
    end

    def cached_file_path
      if store_dir and filename
        @cached_file_path ||= [ store_dir, filename ].join("/")
      end
    end

    protected

    def cache_store_dir
      self[:store_dir] = file.store_dir
    end

    def strip_path
      if filepath.present?
        filepath.slice! "/#{bucket_name}/"
        write_attribute(:filepath, filepath)
        name = filepath.clone

        # 2015-01-06-11-16-33%2Fsome-file.jpg -> some-file.jpg
        # see s3 file structure created in /app/helpers/uploads_helper.rb
        name.slice!(/.*\d{4}-\d{2}-\d{2}-\d{2}-\d{2}-\d{2}%2F/)
        write_attribute(:filename, name)
      end
    end
  end
end
