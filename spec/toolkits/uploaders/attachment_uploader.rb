module Toolkits
  module Uploaders
    module AttachmentUploader
      module MockClass
        # being used to show behaviors when #course, #assignment, or #owner_name methods don't exist
        class EmptyFileKlass
        end

        # being used to show behaviors when these methods are defined on the class
        class FullUpFileKlass
          def course
          end

          def assignment
          end

          def owner_name
          end
        end
      end
    end
  end
end
