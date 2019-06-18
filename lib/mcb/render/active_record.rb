module MCB
  module Render
    module ActiveRecord
      class << self
        include MCB::Render

        def course(course)
          super(
            course.attributes,
            provider:             course.provider,
            accrediting_provider: course.accrediting_provider,
            subjects:             course.subjects,
            site_statuses:        course.site_statuses,
            enrichments:          course.enrichments,
          )
        end

        def user(user)
          super(
            user.attributes,
            providers: user.providers,
          )
        end
      end
    end
  end
end
