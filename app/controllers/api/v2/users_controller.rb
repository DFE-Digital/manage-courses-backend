module API
  module V2
    class UsersController < API::V2::ApplicationController
      before_action :build_user
      deserializable_resource :user, only: :update

      def show
        render jsonapi: @user,
               include: params[:includes]
      end

      def update
        @user.update(user_params)
        render jsonapi: @user
      end

    private

      def build_user
        @user = authorize User.find(params[:id])
      end

      def user_params
        params.require(:user).permit(
          :email,
          :first_name,
          :last_name,
          :first_login_date_utc,
          :last_login_date_utc,
          :sign_in_user_id,
          :welcome_email_date_utc,
          :invite_date_utc,
          :accept_terms_date_utc,
        )
      end
    end
  end
end
