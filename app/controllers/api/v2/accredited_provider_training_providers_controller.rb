module API
  module V2
    class AccreditedProviderTrainingProvidersController < API::V2::ApplicationController
      before_action :build_recruitment_cycle
      before_action :build_provider

      class TrainingProviderSearch
        attr_reader :provider, :params

        def initialize(provider:, params:)
          @provider = provider
          @params = params
        end

        def call
          scope = training_providers.order(:provider_name)

          if params[:filter]
            scope = scope.where(id: eligible_training_provider_ids)
          end

          scope
        end

      private

        def course_scope
          Course.where(provider: training_providers)
                .where(accrediting_provider_code: provider.provider_code)
        end

        def eligible_training_provider_ids
          CourseSearchService.call(filter: params[:filter], course_scope: course_scope)
                             .pluck(:provider_id)
        end

        def training_providers
          provider.training_providers
        end
      end

      def index
        authorize @provider, :can_list_training_providers?

        providers = TrainingProviderSearch.new(provider: @provider, params: params).call

        render jsonapi: providers, include: params[:include]
      end

    private

      def build_recruitment_cycle
        @recruitment_cycle = RecruitmentCycle.find_by(
          year: params[:recruitment_cycle_year],
        ) || RecruitmentCycle.current_recruitment_cycle
      end

      def build_provider
        @provider = @recruitment_cycle.providers.find_by!(
          provider_code: params[:provider_code].upcase,
        )
      end
    end
  end
end
