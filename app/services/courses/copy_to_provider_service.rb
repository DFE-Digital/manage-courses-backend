module Courses
  class CopyToProviderService
    def initialize(course:)
      @course = course
    end

    def execute(new_provider)
      new_course = new_provider.courses.find_by(course_code: @course.course_code)

      return nil if new_course.present?

      new_course = @course.dup
      new_course.subjects << @course.subjects

      new_provider.courses << new_course

      last_enrichment = @course.enrichments.latest_first.first
      last_enrichment.copy_to_course(new_course) if last_enrichment.present?

      @course.sites.each do |site|
        new_site = new_provider.sites.find_by(code: site.code)
        new_site&.copy_to_course(new_course)
      end

      new_course
    end
  end
end
