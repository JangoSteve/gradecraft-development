class AddStoreDirToS3Files < ActiveRecord::Migration
  def change
    %w[ submission grade assignment badge challenge ].each do |file_type|
      add_column :"#{file_type}_files", :store_dir, :string
    end
  end
end
