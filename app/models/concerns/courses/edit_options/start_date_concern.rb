module Courses
  module EditOptions
    module StartDateConcern
      extend ActiveSupport::Concern
      included do
        # When changing anything here be sure to update the edit_options in the
        # courses factory in manage-courses-frontend:
        #
        # https://github.com/DFE-Digital/manage-courses-frontend/blob/master/spec/factories/courses.rb
        def start_date_options
          recruitment_year = provider.recruitment_cycle.year.to_i

          ["August #{recruitment_year}",
           "September #{recruitment_year}",
           "October #{recruitment_year}",
           "November #{recruitment_year}",
           "December #{recruitment_year}",
           "January #{recruitment_year + 1}",
           "February #{recruitment_year + 1}",
           "March #{recruitment_year + 1}",
           "April #{recruitment_year + 1}",
           "May #{recruitment_year + 1}",
           "June #{recruitment_year + 1}",
           "July #{recruitment_year + 1}"]
        end
      end
    end
  end
end
