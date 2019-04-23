class UserPolicy
  attr_reader :user, :accessed_user

  def initialize(user, accessed_user)
    @user = user
    @accessed_user = accessed_user
  end

  def show?
    user == accessed_user
  end

  alias_method :update?, :show?
  alias_method :accept_transition_screen?, :update?
end
