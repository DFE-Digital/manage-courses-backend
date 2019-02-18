module API
  module V2
    class UserSerializable < JSONAPI::Serializable::Resource
      type 'users'

      attributes :first_name, :last_name, :email
    end
  end
end
