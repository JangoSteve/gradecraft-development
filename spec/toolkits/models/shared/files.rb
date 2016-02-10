module Toolkits
  module Models
    module Shared
      module Files

        def define_context
          let(:image_file_attrs) {{ filename: "test_image.jpg", file: fixture_file("test_image.jpg", 'img/jpg') }}
          let(:text_file_attrs) {{ filename: "test_file.txt", file: fixture_file("test_file.txt", 'txt') }}
        end

      end
    end
  end
end
