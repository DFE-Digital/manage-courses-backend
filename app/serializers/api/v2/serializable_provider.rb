module API
  module V2
    class SerializableProvider < JSONAPI::Serializable::Resource
      type 'providers'

      attributes :provider_code, :provider_name, :accredited_body?

      has_many :sites

      has_many :courses do
        meta do
          { count: @object.courses.size }
        end
      end
    end
  end
end
