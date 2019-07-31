module API
  module V2
    class ProvidersController < API::V2::ApplicationController
      before_action :get_user, if: -> { params[:user_id].present? }
      before_action :build_recruitment_cycle
      before_action :build_provider, except: :index

      deserializable_resource :provider,
                              only: %i[update publish publishable],
                              class: API::V2::DeserializableProvider

      def index
        authorize Provider
        providers = policy_scope(@recruitment_cycle.providers)
                      .include_courses_counts
        providers = providers.where(id: @user.providers) if @user.present?

        render jsonapi: providers.in_order,
               fields: { providers: %i[provider_code provider_name courses
                                       recruitment_cycle_year] }
      end

      def show
        authorize @provider, :show?

        render jsonapi: @provider, include: params[:include]
      end

      def update
        authorize @provider, :update?
        update_enrichment

        if @provider.valid?
          render jsonapi: @provider.reload, include: params[:include]
        else
          render jsonapi_errors: @provider.errors, status: :unprocessable_entity, include: params[:include]
        end
      end

      def publish
        authorize @provider, :publish?

        if @provider.publishable?
          head :ok
        else
          render jsonapi_errors: @provider.errors, status: :unprocessable_entity
        end
      end

      def publishable
        authorize @provider, :publishable?

        if @provider.publishable?
          head :ok
        else
          render jsonapi_errors: @provider.errors, status: :unprocessable_entity
        end
      end

      def sync_courses_with_search_and_compare
        provider = Provider.find_by!(provider_code: params[:code].upcase)
        authorize provider
        syncable_courses = provider.syncable_courses
        response = SearchAndCompareAPIService::Request.sync(
          syncable_courses
        )
        if response
          head :ok
        else
          raise RuntimeError.new(
            'error received when syncing courses with search and compare'
          )
        end
      end

    private

      def build_recruitment_cycle
        @recruitment_cycle = RecruitmentCycle.find_by(
          year: params[:recruitment_cycle_year]
        ) || RecruitmentCycle.current_recruitment_cycle
      end

      def build_provider
        code = params.fetch(:code, params[:provider_code])
        @provider = @recruitment_cycle.providers
                      .includes(:latest_published_enrichment, :latest_enrichment)
                      .find_by!(
                        provider_code: code.upcase
                      )
      end

      def get_user
        @user = User.find(params[:user_id])
      end

      def update_enrichment
        return unless enrichment_params.values.any?

        enrichment = @provider.enrichments.find_or_initialize_draft
        enrichment.assign_attributes(enrichment_params)

        # Note: provider_code is only here to support c# counterpart, until provide_code is removed from database
        enrichment.provider_code = @provider.provider_code if enrichment.provider_code.blank?
        enrichment.save
      end

      def enrichment_params
        params
          .fetch(:provider, {})
          .except
          .permit(
            :train_with_us,
            :train_with_disability,
            :email,
            :telephone,
            :website,
            :address1,
            :address2,
            :address3,
            :address4,
            :postcode,
            :region_code
          )
      end
    end
  end
end
