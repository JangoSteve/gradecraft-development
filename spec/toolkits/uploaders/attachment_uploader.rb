module Toolkits
  module Uploaders
    module AttachmentUploader
      module MockClass
        # being used to show behaviors when #course, #assignment, or #owner_name methods don't exist
        class EmptyFileKlass
          def id
            @id ||= rand(1000)
          end
        end

        # being used to show behaviors when these methods are defined on the class
        class FullUpFileKlass < EmptyFileKlass
          def course
          end

          def assignment
          end

          def owner_name
          end
        end

        class MountedClass < FullUpFileKlass
          def read_attribute(mounted_as)
            "mountable_something.pdf" if mounted_as == :file
          end
        end

        class MountedClassWithoutAttribute < FullUpFileKlass
          def read_attribute(mounted_as)
            nil
          end
        end
      end
    end
  end
end
