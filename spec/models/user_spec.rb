# == Schema Information
#
# Table name: user
#
#  id                     :integer          not null, primary key
#  email                  :text
#  first_name             :text
#  last_name              :text
#  first_login_date_utc   :datetime
#  last_login_date_utc    :datetime
#  sign_in_user_id        :text
#  welcome_email_date_utc :datetime
#  invite_date_utc        :datetime
#  accept_terms_date_utc  :datetime
#

require 'rails_helper'

RSpec.describe User, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
