require "rails_helper"

describe "GET v3/recruitment_cycles/:year/courses" do
  let(:request_path) { "/api/v3/recruitment_cycles/2020/courses" }
  let(:current_course) do
    create(:course, site_statuses: [build(:site_status, :findable)], enrichments: [build(:course_enrichment, :published)])
  end

  let(:next_provider) { create(:provider, :next_recruitment_cycle) }
  let(:next_course) do
    create(:course, provider: next_provider, site_statuses: [build(:site_status, :findable)], enrichments: [build(:course_enrichment, :published)])
  end

  before do
    current_course
    next_course
  end

  describe "pagination" do
    it "returns a paginated list of courses in the recruitment cycle" do
      get request_path

      json_response = JSON.parse(response.body)
      course_hashes = json_response["data"]
      expect(course_hashes.count).to eq(1)
      expect(course_hashes.first["id"]).to eq(current_course.id.to_s)

      headers = response.headers

      expect(headers["Per-Page"]).to be_present
      expect(headers["Total"]).to be_present
    end
  end

  describe "course count" do
    it "returns the course count in a meta object" do
      get request_path

      json_response = JSON.parse(response.body)
      meta = json_response["meta"]

      expect(meta["count"]).to be(1)
    end
  end
end

describe "GET v3/courses" do
  let(:findable_status) { build(:site_status, :findable) }
  let(:published_enrichment) { build(:course_enrichment, :published) }

  describe "location filter" do
    context "filters out courses with sites that are too far" do
      let(:provider_a) { create(:provider, provider_name: "Provider A") }
      let(:course_a) do
        create(:course,
               name: "Course A",
               provider: provider_a,
               site_statuses: [build(:site_status, :findable, site: build(:site, latitude: 0, longitude: 0))],
               enrichments: [build(:course_enrichment, :published)])
      end

      let(:provider_b) { create(:provider, provider_name: "Provider B") }
      let(:course_b) do
        create(
          :course,
          name: "Course A",
          provider: provider_b,
          site_statuses: [build(:site_status, :findable, site: build(:site, latitude: 16, longitude: 32))],
          enrichments: [build(:course_enrichment, :published)],
        )
      end

      before do
        course_a
        course_b
      end

      context "with a radius of 5" do
        let(:request_path) { "/api/v3/courses?include=provider&sort=name,provider.provider_name&filter[latitude]=0&filter[longitude]=0&filter[radius]=5" }

        it "returns only courses in range" do
          get request_path

          json_response = JSON.parse(response.body)
          course_hashes = json_response["data"]
          expect(course_hashes.count).to eq(1)
          expect(course_hashes.first["id"]).to eq(course_a.id.to_s)
        end
      end
    end
  end

  describe "ordering" do
    let(:provider_a) { create(:provider, provider_name: "Provider A") }
    let(:course_a) do
      create(:course,
             name: "Course A",
             provider: provider_a,
             site_statuses: [build(:site_status, :findable, site: far_site)],
             enrichments: [build(:course_enrichment, :published)])
    end

    let(:provider_b) { create(:provider, provider_name: "Provider B") }
    let(:course_b) do
      create(
        :course,
        name: "Course A",
        provider: provider_b,
        site_statuses: [build(:site_status, :findable, site: near_site)],
        enrichments: [build(:course_enrichment, :published)],
      )
    end
    let(:near_site) { build(:site, latitude: 0, longitude: 0) }
    let(:far_site) { build(:site, latitude: 1, longitude: 1) }

    before do
      course_a
      course_b
    end

    context "in ascending order" do
      let(:request_path) { "/api/v3/courses?include=provider&sort=name,provider.provider_name" }

      it "returns an ordered list" do
        get request_path

        json_response = JSON.parse(response.body)
        course_hashes = json_response["data"]
        expect(course_hashes.first["id"]).to eq(course_a.id.to_s)
        expect(course_hashes.second["id"]).to eq(course_b.id.to_s)
      end
    end

    context "in descending order" do
      let(:request_path) { "/api/v3/courses?include=provider&sort=-name,-provider.provider_name" }

      it "returns an ordered list" do
        get request_path

        json_response = JSON.parse(response.body)
        course_hashes = json_response["data"]
        expect(course_hashes.first["id"]).to eq(course_b.id.to_s)
        expect(course_hashes.second["id"]).to eq(course_a.id.to_s)
      end
    end

    context "by distance" do
      let(:request_path) { "/api/v3/courses?include=provider&sort=distance&latitude=0&longitude=0" }

      it "returns course with closet site first" do
        get request_path

        json_response = JSON.parse(response.body)
        course_hashes = json_response["data"]
        expect(course_hashes.first["id"]).to eq(course_b.id.to_s)
        expect(course_hashes.second["id"]).to eq(course_a.id.to_s)
      end
    end
  end

  describe "without filter params" do
    let(:request_path) { "/api/v3/courses" }
    let(:current_course) do
      create(:course, site_statuses: [build(:site_status, :findable)], enrichments: [build(:course_enrichment, :published)])
    end

    let(:next_provider) { create(:provider, :next_recruitment_cycle) }
    let(:next_course) do
      create(:course, provider: next_provider, site_statuses: [build(:site_status, :findable)], enrichments: [build(:course_enrichment, :published)])
    end

    before do
      current_course
      next_course
    end

    it "returns a paginated list of current cycle courses" do
      get request_path

      json_response = JSON.parse(response.body)
      course_hashes = json_response["data"]
      expect(course_hashes.count).to eq(1)
      expect(course_hashes.first["id"]).to eq(current_course.id.to_s)

      headers = response.headers

      expect(headers["Per-Page"]).to be_present
      expect(headers["Total"]).to be_present
    end
  end

  describe "funding filter" do
    let(:request_path) { "/api/v3/courses?filter[funding]=salary" }

    context "with a salaried course" do
      let(:course_with_salary) { create(:course, :with_salary, site_statuses: [findable_status], enrichments: [published_enrichment]) }

      before do
        course_with_salary
      end

      it "is returned" do
        get request_path
        json_response = JSON.parse(response.body)
        course_hashes = json_response["data"]
        expect(course_hashes.count).to eq(1)
      end
    end

    context "with a non-salaried course" do
      let(:non_salary_course) { create(:course, site_statuses: [findable_status], enrichments: [published_enrichment]) }

      before do
        non_salary_course
      end

      it "is not returned" do
        get request_path
        json_response = JSON.parse(response.body)
        course_hashes = json_response["data"]
        expect(course_hashes).to be_empty
      end
    end
  end

  describe "qualifications filter" do
    let(:request_path) { "/api/v3/courses?filter[qualification]=pgce" }

    context "with a pgce qualification" do
      let(:course_with_pgce) { create(:course, :resulting_in_pgce, site_statuses: [findable_status], enrichments: [published_enrichment]) }

      before do
        course_with_pgce
      end

      it "is returned" do
        get request_path
        json_response = JSON.parse(response.body)
        course_hashes = json_response["data"]
        expect(course_hashes.count).to eq(1)
      end
    end

    context "without a pgce qualification" do
      let(:course_without_pgce) { create(:course, site_statuses: [findable_status], enrichments: [published_enrichment]) }

      before do
        course_without_pgce
      end

      it "is not returned" do
        get request_path
        json_response = JSON.parse(response.body)
        course_hashes = json_response["data"]
        expect(course_hashes.count).to eq(0)
      end
    end
  end

  describe "vacancies filter" do
    let(:request_path) { "/api/v3/courses?filter[has_vacancies]=true" }

    context "with a course with vacancies" do
      let(:findable_status_with_vacancies) { build(:site_status, :findable, :with_any_vacancy) }
      let(:course_with_vacancies) { create(:course, site_statuses: [findable_status_with_vacancies], enrichments: [published_enrichment]) }

      before do
        course_with_vacancies
      end

      it "is returned" do
        get request_path
        json_response = JSON.parse(response.body)
        course_hashes = json_response["data"]
        expect(course_hashes.count).to eq(1)
      end
    end

    context "with a course with no vacancies" do
      let(:findable_status_with_no_vacancies) { build(:site_status, :findable, :with_no_vacancies) }
      let(:course_without_vacancies) { create(:course, site_statuses: [findable_status_with_no_vacancies], enrichments: [published_enrichment]) }

      before do
        course_without_vacancies
      end

      it "is not returned" do
        get request_path
        json_response = JSON.parse(response.body)
        course_hashes = json_response["data"]
        expect(course_hashes.count).to eq(0)
      end
    end
  end

  describe "study type filter" do
    let(:request_path) { "/api/v3/courses?filter[study_type]=full_time" }

    context "with a full time course" do
      let(:full_time_course) { create(:course, study_mode: :full_time, site_statuses: [findable_status], enrichments: [published_enrichment]) }

      before do
        full_time_course
      end

      it "is returned" do
        get request_path
        json_response = JSON.parse(response.body)
        course_hashes = json_response["data"]
        expect(course_hashes.count).to eq(1)
      end
    end

    context "with a part time course" do
      let(:part_time_course) { create(:course, study_mode: :part_time, enrichments: [published_enrichment]) }

      before do
        part_time_course
      end

      it "is not returned" do
        get request_path
        json_response = JSON.parse(response.body)
        course_hashes = json_response["data"]
        expect(course_hashes.count).to eq(0)
      end
    end
  end

  describe "subjects filter" do
    let(:course_with_A1_subject) do
      create(:course,
             enrichments: [published_enrichment],
             site_statuses: [findable_status],
             subjects: [create(:primary_subject, subject_code: "A1")])
    end

    context "with courses that match a single subject" do
      let(:request_path) { "/api/v3/courses?filter[subjects]=A1" }

      before do
        course_with_A1_subject
      end

      it "is returned" do
        get request_path
        json_response = JSON.parse(response.body)
        course_hashes = json_response["data"]
        expect(course_hashes.count).to eq(1)
      end
    end

    context "with courses that match multiple subjects" do
      let(:request_path) { "/api/v3/courses?filter[subjects]=A1,B1" }
      let(:course_with_B1_subject) do
        create(:course,
               enrichments: [published_enrichment],
               site_statuses: [build(:site_status, :findable)],
               subjects: [create(:primary_subject, subject_code: "B1")])
      end

      before do
        course_with_A1_subject
        course_with_B1_subject
      end

      it "is returned" do
        get request_path
        json_response = JSON.parse(response.body)
        course_hashes = json_response["data"]
        expect(course_hashes.count).to eq(2)
      end
    end

    context "with courses that match no subjects" do
      let(:request_path) { "/api/v3/courses?filter[subjects]=C1" }

      before do
        course_with_A1_subject
      end

      it "is not returned" do
        get request_path
        json_response = JSON.parse(response.body)
        course_hashes = json_response["data"]
        expect(course_hashes.count).to eq(0)
      end
    end
  end

  describe "provider filter" do
    context "with a provider specified" do
      let(:request_path) { "/api/v3/courses?filter[provider.provider_name]=#{filtered_provider_course.provider.provider_name}" }
      let(:provider_filtered_by) { create(:provider) }
      let(:filtered_provider_course) { create(:course, provider: provider_filtered_by, site_statuses: [findable_status], enrichments: [published_enrichment]) }

      before do
        provider_filtered_by
        filtered_provider_course
      end

      it "is returned" do
        get request_path
        json_response = JSON.parse(response.body)
        course_hashes = json_response["data"]
        expect(course_hashes.count).to eq(1)
      end
    end

    context "with a different provider specified" do
      let(:request_path) { "/api/v3/courses?filter[provider.provider_name]=a+different+provider" }
      let(:provider_excluded) { create(:provider) }
      let(:excluded_provider_course) { create(:course, provider: provider_excluded, site_statuses: [build(:site_status, :findable)], enrichments: [published_enrichment]) }

      before do
        provider_excluded
        excluded_provider_course
      end

      it "is not returned" do
        get request_path
        json_response = JSON.parse(response.body)
        course_hashes = json_response["data"]
        expect(course_hashes.count).to eq(0)
      end
    end
  end

  describe "SEND courses filter" do
    let(:request_path) { "/api/v3/courses?filter[send_courses]=true" }

    context "with a SEND course" do
      let(:send_course) { create(:course, is_send: true, site_statuses: [findable_status], enrichments: [published_enrichment]) }

      before do
        send_course
      end

      it "is returned" do
        get request_path
        json_response = JSON.parse(response.body)
        course_hashes = json_response["data"]
        expect(course_hashes.count).to eq(1)
      end
    end

    context "with a course without SEND specialism" do
      let(:course) { create(:course, site_statuses: [findable_status], enrichments: [published_enrichment]) }

      before do
        course
      end

      it "is not returned" do
        get request_path
        json_response = JSON.parse(response.body)
        course_hashes = json_response["data"]
        expect(course_hashes.count).to eq(0)
      end
    end
  end

  describe "recruitment_cycle scoping" do
    context "course not in the provided recruitment cycle" do
      let(:provider) { create(:provider, :next_recruitment_cycle) }
      let(:request_path) { "/api/v3/courses" }

      let(:course_in_next_cycle) { create(:course, provider: provider, site_statuses: [findable_status], enrichments: [published_enrichment]) }

      before do
        course_in_next_cycle
      end

      it "is not returned" do
        get request_path
        json_response = JSON.parse(response.body)
        course_hashes = json_response["data"]
        expect(course_hashes.count).to eq(0)
      end
    end
  end

  describe "findable scoping" do
    context "course is not findable" do
      let(:request_path) { "/api/v3/courses" }
      let(:not_findable_course) { create(:course) }

      before do
        not_findable_course
      end

      it "is not returned" do
        get request_path
        json_response = JSON.parse(response.body)
        course_hashes = json_response["data"]
        expect(course_hashes.count).to eq(0)
      end
    end
  end

  describe "published scoping" do
    context "course is not currently published" do
      let(:request_path) { "/api/v3/courses" }
      let(:not_published_course) { create(:course, enrichments: [build(:course_enrichment, :withdrawn)]) }

      before do
        not_published_course
      end

      it "is not returned" do
        get request_path
        json_response = JSON.parse(response.body)
        course_hashes = json_response["data"]
        expect(course_hashes.count).to eq(0)
      end
    end
  end

  describe "pagination" do
    let(:request_path) { "/api/v3/courses" }

    it "paginates the results" do
      get request_path
      headers = response.headers

      expect(headers["Per-Page"]).to be_present
      expect(headers["Total"]).to be_present
    end

    context "can be disabled for sitemap" do
      before do
        create(:course, site_statuses: [build(:site_status, :findable)], enrichments: [build(:course_enrichment, :published)])
        create(:course, site_statuses: [build(:site_status, :findable)], enrichments: [build(:course_enrichment, :published)])
      end

      around do |example|
        default_per_page = Kaminari.config.default_per_page

        Kaminari.configure do |config|
          config.default_per_page = 1
        end

        example.run

        Kaminari.configure do |config|
          config.default_per_page = default_per_page
        end
      end

      let(:request_path) { "/api/v3/courses?page[per_page]=1000&fields[courses]=course_code,provider_code,changed_at" }

      it "returns all results" do
        get request_path

        json_response = JSON.parse(response.body)
        course_hashes = json_response["data"]
        expect(course_hashes.count).to eq(2)
      end

      it "returns only specified fields" do
        get request_path

        keys = JSON.parse(response.body)["data"][0]["attributes"].keys
        expect(keys).to eql(%w{course_code changed_at provider_code})
      end
    end
  end

  describe "courses with non-locatable sites" do
    # This functionality has been added to handle address data
    # that is currently missing from the DB. New sites are validated for
    # address but a historical import allowed some sites to be added without valid
    # addresses. The intention is to fix this data.
    let(:request_path) { "/api/v3/courses" }
    let!(:course) do
      create(:course, site_statuses: [build(:site_status, :findable, site: site)], enrichments: [build(:course_enrichment, :published)])
    end

    context "a course with an invalid site" do
      let(:site) do
        build(:site, address1: "", postcode: "").tap do |site|
          site.save(validate: false)
        end
      end

      it "is not returned" do
        get request_path
        expect(JSON.parse(response.body)["data"]).to be_empty
      end
    end

    context "a course with a valid site" do
      let(:site) { build(:site) }

      it "is returned" do
        get request_path
        expect(JSON.parse(response.body)["data"].first["id"]).to eq(course.id.to_s)
      end
    end
  end
end
