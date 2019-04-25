class AuthenticationService
  attr_accessor :encoded_token, :user

  def self.call(encoded_token)
    new(encoded_token).call
  end

  def initialize(encoded_token)
    @encoded_token = encoded_token
  end

  def call
    @user = user_by_sign_in_user_id || user_by_email
    update_user_email if user_email_does_not_match_token?

    user
  end

private

  def decoded_token
    @decoded_token ||= JWT.decode(
      encoded_token,
      Settings.authentication.secret,
      Settings.authentication.algorithm
    )
    (decoded_token_payload, _algorithm) = @decoded_token

    decoded_token_payload
  end

  def email_from_token
    decoded_token['email']&.downcase
  end

  def sign_in_user_id_from_token
    decoded_token['sign_in_user_id']
  end

  def user_by_email
    return unless email_from_token.present?

    User.find_by("lower(email) = ?", email_from_token)
  end

  def user_by_sign_in_user_id
    return unless sign_in_user_id_from_token.present?

    User.find_by(sign_in_user_id: sign_in_user_id_from_token)
  end

  def user_email_does_not_match_token?
    return unless user

    user.email&.downcase != email_from_token
  end

  def update_user_email
    user.update(email: email_from_token)
  end
end
