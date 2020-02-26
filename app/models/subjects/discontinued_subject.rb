# == Schema Information
#
# Table name: subject
#
#  id           :bigint           not null, primary key
#  subject_code :text
#  subject_name :text
#  type         :text
#
# Indexes
#
#  index_subject_on_subject_code  (subject_code)
#  index_subject_on_subject_name  (subject_name)
#  index_subject_on_type          (type)
#

class DiscontinuedSubject < Subject
end
