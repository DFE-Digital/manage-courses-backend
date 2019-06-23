# == Schema Information
#
# Table name: course
#
#  id                      :integer          not null, primary key
#  age_range               :text
#  course_code             :text
#  name                    :text
#  profpost_flag           :text
#  program_type            :text
#  qualification           :integer          not null
#  start_date              :datetime
#  study_mode              :text
#  accrediting_provider_id :integer
#  provider_id             :integer          default(0), not null
#  modular                 :text
#  english                 :integer
#  maths                   :integer
#  science                 :integer
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  changed_at              :datetime         not null
#  recruitment_cycle_id    :integer          not null
#

class Course < ApplicationRecord
  DEFAULT_RECRUITMENT_CYCLE_YEAR = "2019".freeze

  include SpreadsheetArchitect

  include WithQualifications
  include ChangedAt
  include AllocationSubjects

  after_initialize :set_defaults

  has_associated_audits
  audited except: :changed_at
  validates :course_code, uniqueness: { scope: :provider_id }

  enum program_type: {
    higher_education_programme: "HE",
    school_direct_training_programme: "SD",
    school_direct_salaried_training_programme: "SS",
    scitt_programme: "SC",
    pg_teaching_apprenticeship: "TA",
  }

  enum study_mode: {
    full_time: "F",
    part_time: "P",
    full_time_or_part_time: "B",
  }

  enum age_range: {
    primary: "P",
    secondary: "S",
    middle_years: "M",
    # 'other' doesn't exist in the data yet but is reserved for courses that don't fit
    # the above categories
    other: "O",
  }

  ENTRY_REQUIREMENT_OPTIONS = {
    must_have_qualification_at_application_time: 1,
    expect_to_achieve_before_training_begins: 2,
    equivalence_test: 3,
    not_required: 9,
    not_set: nil,
  }.freeze

  enum maths: ENTRY_REQUIREMENT_OPTIONS, _suffix: :for_maths
  enum english: ENTRY_REQUIREMENT_OPTIONS, _suffix: :for_english
  enum science: ENTRY_REQUIREMENT_OPTIONS, _suffix: :for_science

  belongs_to :provider
  belongs_to :accrediting_provider, class_name: 'Provider', optional: true
  belongs_to :recruitment_cycle
  has_many :course_subjects
  has_many :subjects, through: :course_subjects
  has_many :site_statuses
  has_many :sites,
           -> { merge(SiteStatus.where(status: %i[new_status running])) },
           through: :site_statuses

  has_many :enrichments,
           ->(course) { where(provider_code: course.provider.provider_code) },
           foreign_key: :ucas_course_code,
           primary_key: :course_code,
           class_name: 'CourseEnrichment' do
    def find_or_initialize_draft
      latest_draft_enrichment = latest_first.draft.first

      if latest_draft_enrichment.present?
        latest_draft_enrichment
      else
        new(new_draft_attributes)
      end
    end

    def new_draft_attributes
      latest_published_enrichment = latest_first.published.first

      new_enrichments_attributes = { status: :draft }.with_indifferent_access

      if latest_published_enrichment.present?
        published_enrichment_attributes = latest_published_enrichment.dup.attributes.with_indifferent_access
          .except(:json_data, :status)

        new_enrichments_attributes.merge!(published_enrichment_attributes)
      end

      new_enrichments_attributes
    end
  end

  scope :changed_since, ->(timestamp) do
    if timestamp.present?
      where("course.changed_at > ?", timestamp)
    else
      where.not(changed_at: nil)
    end.order(:changed_at, :id)
  end

  validates :enrichments, presence: true, on: :publish
  validate :validate_enrichment_publishable, on: :publish
  validate :validate_enrichment_saveable, on: :save

  def accrediting_provider_description
    return nil if accrediting_provider.blank?

    provider_enrichment = provider
                            .enrichments
                            .published
                            .latest_published_at
                            .first

    return nil if provider_enrichment&.accrediting_provider_enrichments.blank?

    accrediting_provider_enrichment = provider_enrichment.accrediting_provider_enrichments
      .find do |provider|
      provider['UcasProviderCode'] == accrediting_provider.provider_code
    end

    accrediting_provider_enrichment['Description'] unless accrediting_provider_enrichment.blank?
  end

  def publishable?
    valid? :publish
  end

  def saveable?
    valid? :save
  end

  def recruitment_cycle_year
    DEFAULT_RECRUITMENT_CYCLE_YEAR
  end

  def findable?
    site_statuses.findable.any?
  end

  def not_discontinued?
    site_statuses.not_discontinued.any?
  end

  def allocations_report_fields
    [
      provider.provider_code,
      accrediting_provider&.provider_code,
      provider.organisations.first&.school_nctl_organisation&.urn,
      allocation_subjects.join(' | '),
      program_type,
      qualification
    ]
  end

  def spreadsheet_columns
    [
      ['Academic Year', '2020/21'],
      ['Requested By (Name)', accrediting_provider&.provider_name],
      ['Requested by (UKPRN)', ''],
      ['Partner ITT Provider (Name)', provider.provider_name],
      ['Partner ITT provider (UKPRN)', provider.organisations.first&.school_nctl_organisation&.urn],
      ['Allocation Subject', allocation_subjects.join(' | ')],
      ['Route', program_type],
      ['Course Aim', qualification],
      ['Course Level', 'PG'],
      ['Min. no. of recruits', ''],
      ['Forecast no. of recruits ', ''],
      ['3 Year Intention', ''],
      ['Awarding Institution', ''],
      ['Other Institution', '']
    ]
  end

  # Outputs an allocations XLSX with a randomly generated suffix to `public/`.
  # The first argument is an optional prefix for the filename to make it
  # easier to differentiate among ~200 other similar XLSX files. Defaults to
  # the provider.provider_code.
  # The filename will have a UUID prefix so that it can be hosted
  # and linked to from an Azure bucket, but that the names can't be
  # simply guessed.
  # Example usage:
  #    $ bin/rails c
  #    > Course.save_xlsx(Course.first(20))
  def self.save_allocations_report(file_name_prefix = all.first.provider.provider_code)
    file_data = all.to_xlsx

    file_name_suffix = SecureRandom.uuid

    File.open(Rails.root.join("public", "allocations-#{file_name_prefix}-#{file_name_suffix}.xlsx"), 'w+b') do |f|
      f.write file_data
    end
  end

  def open_for_applications?
    site_statuses.open_for_applications.any?
  end

  def applications_open_from
    site_statuses
      .open_for_applications
      .order("applications_accepted_from ASC")
      .first
      &.applications_accepted_from
      &.to_datetime
      &.utc
      &.iso8601
  end

  def applications_open_from=(new_date)
    site_statuses.each { |ss| ss.update(applications_accepted_from: new_date) }
  end

  def has_vacancies?
    site_statuses.findable.with_vacancies.any?
  end

  def update_changed_at(timestamp: Time.now.utc)
    # Changed_at represents changes to related records as well as course
    # itself, so we don't want to alter the semantics of updated_at which
    # represents changes to just the course record.
    update_columns changed_at: timestamp
  end

  def study_mode_description
    study_mode.to_s.tr("_", " ")
  end

  def program_type_description
    if school_direct_salaried_training_programme? then " with salary"
    elsif pg_teaching_apprenticeship? then " teaching apprenticeship"
    else ""
    end
  end

  def description
    study_mode_string = (full_time_or_part_time? ? ", " : " ") +
      study_mode_description
    qualifications_description + study_mode_string + program_type_description
  end

  def content_status
    newest_enrichment = enrichments.latest_first.first

    if newest_enrichment.nil?
      :empty
    elsif newest_enrichment.published?
      :published
    elsif newest_enrichment.has_been_published_before?
      :published_with_unpublished_changes
    else
      :draft
    end
  end

  def ucas_status
    return :running if findable?
    return :new if site_statuses.empty? || site_statuses.status_new_status.any?

    :not_running
  end

  def funding
    if school_direct_salaried_training_programme?
      'salary'
    elsif pg_teaching_apprenticeship?
      'apprenticeship'
    else
      'fee'
    end
  end

  def dfe_subjects
    SubjectMapperService.get_subject_list(name, subjects.map(&:subject_name))
  end

  def level
    Subjects::CourseLevel.new(subjects.map(&:subject_name)).level
  end

  def is_send?
    subjects.any?(&:is_send?)
  end

  def is_fee_based?
    funding == 'fee'
  end

  def last_published_at
    newest_enrichment = enrichments.latest_first.first
    newest_enrichment&.last_published_timestamp_utc
  end

  def publish_sites
    site_statuses.status_new_status.each(&:start!)
    site_statuses.status_running.unpublished_on_ucas.each(&:published_on_ucas!)
  end

  def publish_enrichment(current_user)
    enrichments.draft.each do |enrichment|
      enrichment.publish(current_user)
    end
  end

  def add_site!(site:)
    is_course_new = ucas_status == :new # persist this before we change anything
    site_status = site_statuses.find_or_initialize_by(site: site)
    site_status.start! unless is_course_new
    site_status.save! if persisted?
  end

  def remove_site!(site:)
    site_status = site_statuses.find_by!(site: site)
    ucas_status == :new ? site_status.destroy! : site_status.suspend!
  end

  def sites=(desired_sites)
    existing_sites = sites

    to_add = desired_sites - existing_sites
    to_add.each { |site| add_site!(site: site) }

    to_remove = existing_sites - desired_sites
    to_remove.each { |site| remove_site!(site: site) }

    sites.reload
  end

  def has_bursary?
    dfe_subjects.any?(&:has_bursary?)
  end

  def has_scholarship_and_bursary?
    dfe_subjects.any?(&:has_scholarship_and_bursary?)
  end

  def has_early_career_payments?
    dfe_subjects.any?(&:has_early_career_payments?)
  end

  def bursary_amount
    dfe_subjects&.first&.bursary_amount
  end

  def scholarship_amount
    dfe_subjects&.first&.scholarship_amount
  end

  def to_s
    "#{name} (#{course_code})"
  end

private

  def add_enrichment_errors(enrichment)
    enrichment.errors.messages.map do |field, _error|
      # `full_messages_for` here will remove any `^`s defined in the validator or en.yml.
      # We still need it for later, so re-add it.
      # jsonapi_errors will throw if it's given an array, so we call `.first`.
      message = "^" + enrichment.errors.full_messages_for(field).first.to_s
      errors.add field.to_sym, message
    end
  end

  def validate_enrichment(validation_scope)
    latest_enrichment = enrichments.latest_first.first
    return unless latest_enrichment.present?

    latest_enrichment.valid? validation_scope
    add_enrichment_errors(latest_enrichment)
  end

  def validate_enrichment_publishable
    validate_enrichment :publish
  end

  def validate_enrichment_saveable
    validate_enrichment :save
  end

  def set_defaults
    self.modular ||= ''
  end
end
