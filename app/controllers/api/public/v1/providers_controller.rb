module API
  module Public
    module V1
      class ProvidersController < API::Public::V1::ApplicationController
        def index
          providers = recruitment_cycle.providers
          providers = if sort_by_provider_ascending?
                        providers.by_name_ascending
                      else
                        providers.by_name_descending
                      end
          render jsonapi: providers, class: { Provider: API::Public::V1::SerializableProvider }, fields: { providers: provider_fields }
        end

        def show
          render json: {
            data: {
              id: 123,
              type: "Provider",
              attributes: {
                code: "ABC",
                name: "Some provider",
              },
            },
            jsonapi: {
              version: "1.0",
            },
          }
        end

      private

        def sort_by_provider_ascending?
          sort_field.include?("name") || !sort_by_provider_descending?
        end

        def sort_by_provider_descending?
          sort_field.include?("-name")
        end

        def sort_field
          @sort_field ||= Set.new(params.dig(:sort)&.split(","))
        end

        def recruitment_cycle
          RecruitmentCycle.find_by(
            year: params[:recruitment_cycle_year],
          ) || RecruitmentCycle.current_recruitment_cycle
        end

        def provider_fields
          params.dig(:fields, :providers)&.split(",") || %i[
             accredited_body
             changed_at
             city
             code
             county
             created_at
             name
             postcode
             provider_type
             recruitment_cycle_year
             region_code
             street_address_1
             street_address_2
             train_with_disability
             train_with_us
             website
            ]
        end
      end
    end
  end
end
