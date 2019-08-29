class UserPolicy
  attr_reader :user, :accessed_user

  def initialize(user, accessed_user)
    @user = user
    @accessed_user = accessed_user
  end

  def show?
    user == accessed_user
  end

  def remove_access_to?
    user == accessed_user || user.admin?
  end

  alias_method :update?, :show?
  alias_method :accept_transition_screen?, :update?
  alias_method :accept_rollover_screen?, :update?
end
