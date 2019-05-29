module API
  module V2
    class CoursesController < API::V2::ApplicationController
      before_action :build_provider
      before_action :build_course, except: :index

      def index
        authorize @provider, :can_list_courses?
        authorize Course

        render jsonapi: @provider.courses, include: params[:include]
      end

      def show
        render jsonapi: @course, include: params[:include]
      end

      def sync_with_search_and_compare
        response = ManageCoursesAPIService::Request.sync_course_with_search_and_compare(
          @current_user.email,
          @provider.provider_code,
          @course.course_code
        )

        head response ? :ok : :internal_server_error
      end

      def publish
        if @course.publishable?
          @course.publish_sites
          @course.publish_enrichment(@current_user)

          response = ManageCoursesAPIService::Request.sync_course_with_search_and_compare(
            @current_user.email,
            @provider.provider_code,
            @course.course_code
          )

          head response ? :ok : :internal_server_error
        else
          render jsonapi_errors: @course.errors, status: :unprocessable_entity
        end
      end

    private

      def build_provider
        @provider = Provider.find_by!(provider_code: params[:provider_code].upcase)
      end

      def build_course
        @course = @provider.courses.find_by!(course_code: params[:code].upcase)

        authorize @course
      end
    end
  end
end
