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
#  index_subject_on_subject_name  (subject_name)
#

class SubjectSerializer < ActiveModel::Serializer
  attributes :subject_name, :subject_code, :type
end
