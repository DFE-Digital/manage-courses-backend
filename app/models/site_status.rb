# == Schema Information
#
# Table name: course_site
#
#  id                         :integer          not null, primary key
#  applications_accepted_from :date
#  course_id                  :integer
#  publish                    :text
#  site_id                    :integer
#  status                     :text
#  vac_status                 :text
#

class SiteStatus < ApplicationRecord
  self.table_name = "course_site"

  enum vac_status: {
    "Both full time and part time vacancies" => "B",
    "Part time vacancies" => "P",
    "Full time vacancies" => "F",
    "No vacancies" => "",
  }

  enum status: {
    "Discontinued" => "D",
    "Running" => "R",
    "New" => "N",
    "Suspended" => "S",
  }

  belongs_to :site
  belongs_to :course

  def recruitment_cycle
    "2019"
  end

  def findable?
    status == "Running" && publish == 'Y'
  end

  def has_vacancies?
    [
      "Both full time and part time vacancies",
      "Part time vacancies",
      "Full time vacancies"
    ].include?(vac_status)
  end

  def applications_being_accepted_now?
    applications_accepted_from.present? && applications_accepted_from <= Time.now.utc
  end
end
