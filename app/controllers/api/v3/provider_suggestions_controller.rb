module API
  module V3
    class ProviderSuggestionsController < API::V3::ApplicationController
      before_action :build_recruitment_cycle

      def index
        return render(status: :bad_request) if params[:query].nil? || params[:query].length < 3

        normalise_query = CGI.unescape(params[:query]).downcase.gsub(/[^0-9a-z]/i, "")

        found_providers = @recruitment_cycle.providers
                              .with_findable_courses
                              .search_by_code_or_name(normalise_query)
                              .limit(10)

        render(
          jsonapi: found_providers,
          class: { Provider: SerializableProvider },
        )
      end

    private

      def begins_with_alphanumeric(string)
        string.match?(/^[[:alnum:]].*$/)
      end
    end
  end
end
