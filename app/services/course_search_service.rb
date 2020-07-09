class CourseSearchService
  def initialize(filter:, sort: nil, course_scope: Course)
    @filter = filter || {}
    @course_scope = course_scope
    @sort = Set.new(sort&.split(","))
  end

  class << self
    def call(**args)
      new(args).call
    end
  end

  def call
    scope = course_scope.findable
    scope = scope.with_salary if funding_filter_salary?
    scope = scope.with_qualifications(qualifications) if qualifications.any?
    scope = scope.with_vacancies if has_vacancies?
    scope = scope.with_study_modes(study_types) if study_types.any?
    scope = scope.with_subjects(subject_codes) if subject_codes.any?
    scope = scope.with_provider_name(provider_name) if provider_name.present?
    scope = scope.with_send if send_courses_filter?
    scope = scope.within(filter[:radius], origin: origin) if locations_filter?
    scope = scope.with_funding_types(funding_types) if funding_types.any?

    # The 'where' scope will remove duplicates
    # An outer query is required in the event the provider name is present.
    # This prevents 'PG::InvalidColumnReference: ERROR: for SELECT DISTINCT, ORDER BY expressions must appear in select list'
    outer_scope = Course.where(id: scope.select(:id))

    if provider_name.present?
      outer_scope = outer_scope
                      .accredited_body_order(provider_name)
                      .ascending_canonical_order
    elsif sort_by_provider_ascending?
      outer_scope = outer_scope.ascending_canonical_order
      outer_scope = outer_scope.select("provider.provider_name", "course.*")
    elsif sort_by_provider_descending?
      outer_scope = outer_scope.descending_canonical_order
      outer_scope = outer_scope.select("provider.provider_name", "course.*")
    elsif sort_by_distance?
      outer_scope = outer_scope.joins(courses_with_distance_from_origin)
      outer_scope = outer_scope.joins(:provider)
      outer_scope = outer_scope.select("course.*, distance, #{distance_with_university_area_adjustment}")
      outer_scope = outer_scope.order(:boosted_distance)
    end

    outer_scope
  end

  private_class_method :new

private

  def distance_with_university_area_adjustment
    university_provider_type = Provider.provider_types[:university]
    university_location_area_radius = 10
    <<~EOSQL.gsub(/^[\s\t]*/, "").gsub(/[\s\t]*\n/, " ").strip
      (CASE
        WHEN provider.provider_type = '#{university_provider_type}'
          THEN (distance - #{university_location_area_radius})
        ELSE distance
      END) as boosted_distance
    EOSQL
  end

  def locatable_sites
    site_status = SiteStatus.arel_table
    sites = Site.arel_table

    # Only running and published site statuses
    running_and_published_criteria = site_status[:status].eq(SiteStatus.statuses[:running]).and(site_status[:publish].eq(SiteStatus.publishes[:published]))

    # we only want sites that have been geocoded
    has_been_geocoded_criteria = sites[:latitude].not_eq(nil).and(sites[:longitude].not_eq(nil))

    # only sites that have a locatable address
    # there are some sites with no address1 or postcode that cannot be
    # accurately geocoded. We don't want to return these as the closest site.
    # This should be removed once the data is fixed
    locatable_address_criteria = sites[:address1].not_eq("").or(sites[:postcode].not_eq(""))

    # Create virtual table with sites and site statuses
    site_status.join(sites).on(site_status[:site_id].eq(sites[:id]))
     .where(running_and_published_criteria)
     .where(has_been_geocoded_criteria)
     .where(locatable_address_criteria)
  end

  def course_id_with_lowest_locatable_distance
    # select course_id and nearest site with shortest distance from origin
    # as courses may have multiple sites
    # this will remove duplicates by aggregating on course_id
    locatable_sites.project(:course_id, Arel.sql("MIN#{Site.distance_sql(OpenStruct.new(lat: origin[0], lng: origin[1]))} as distance")).group(:course_id)
  end

  def distance_table
    # form a temporary table with results
    Arel::Nodes::TableAlias.new(
      Arel.sql(
        format("(%s)", course_id_with_lowest_locatable_distance.to_sql),
      ), "distances"
    )
  end

  def courses_with_distance_from_origin
    # grab courses table and join with the above result set
    # so distances from origin are now available
    # we can then sort by distance from the given origin
    courses_table = Course.arel_table
    courses_table.join(distance_table).on(courses_table[:id].eq(distance_table[:course_id])).join_sources
  end

  def locations_filter?
    filter.has_key?(:latitude) &&
      filter.has_key?(:longitude) &&
      filter.has_key?(:radius)
  end

  def sort_by_provider_ascending?
    sort == Set["name", "provider.provider_name"]
  end

  def sort_by_provider_descending?
    sort == Set["-name", "-provider.provider_name"]
  end

  def sort_by_distance?
    sort == Set["distance"]
  end

  def origin
    [filter[:latitude], filter[:longitude]]
  end

  attr_reader :sort, :filter, :course_scope

  def funding_filter_salary?
    filter[:funding] == "salary"
  end

  def qualifications
    return [] if filter[:qualification].blank?

    filter[:qualification].split(",")
  end

  def has_vacancies?
    filter[:has_vacancies].to_s.downcase == "true"
  end

  def study_types
    return [] if filter[:study_type].blank?

    filter[:study_type].split(",")
  end

  def funding_types
    return [] if filter[:funding_type].blank?

    filter[:funding_type].split(",")
  end

  def subject_codes
    return [] if filter[:subjects].blank?

    filter[:subjects].split(",")
  end

  def provider_name
    return [] if filter[:"provider.provider_name"].blank?

    filter[:"provider.provider_name"]
  end

  def send_courses_filter?
    filter[:send_courses].to_s.downcase == "true"
  end
end
