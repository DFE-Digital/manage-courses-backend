module API
  module V3
    class SerializableProvider < JSONAPI::Serializable::Resource
      type "providers"

      attributes :provider_code, :provider_name, :provider_type,
                 :latitude, :longitude, :can_sponsor_student_visa,
                 :can_sponsor_skilled_worker_visa

      attribute :recruitment_cycle_year do
        @object.recruitment_cycle.year
      end
    end
  end
end
