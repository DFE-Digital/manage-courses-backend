require "swagger_helper"

describe "API" do
  path "/recruitment_cycles/{year}/providers/{provider_code}/courses" do
    get "Returns the courses for the specified provider." do
      operationId :public_api_v1_provider_courses
      tags "course"
      produces "application/json"
      parameter name: :year,
                in: :path,
                type: :string,
                required: true,
                description: "The starting year of the recruitment cycle.",
                example: "2020"
      parameter name: :provider_code,
                in: :path,
                type: :string,
                required: true,
                description: "The unique code of the provider.",
                example: "T92"
      parameter name: :filter,
                in: :query,
                schema: { "$ref" => "#/components/schemas/Filter" },
                type: :object,
                style: :deepObject,
                explode: true,
                required: false,
                description: "Refine courses to return.",
                example: "filter[has_vacancies]=true&filter[subjects]=00,01"
      parameter name: :sort,
                in: :query,
                schema: { "$ref" => "#/components/schemas/Sort" },
                type: :object,
                style: :form,
                explode: false,
                required: false,
                example: "provider.provider_name,name",
                description: "Field(s) to sort the courses by."
      parameter name: :page,
                in: :query,
                schema: { "$ref" => "#/components/schemas/Pagination" },
                type: :object,
                style: :form,
                explode: false,
                required: false,
                example: "page[page]=2&page[per_page]=10",
                description: "Pagination options to navigate through the collection."

      response "200", "The collection of courses." do
        let(:year) { "2020" }
        let(:provider_code) { "ABC" }

        schema "$ref": "#/components/schemas/CourseListResponse"

        run_test!
      end
    end
  end

  path "/recruitment_cycles/{year}/providers/{provider_code}/courses/{course_code}" do
    get "Returns the specified course for the specified provider." do
      operationId :public_api_v1_provider_course
      tags "course"
      produces "application/json"
      parameter name: :year,
                in: :path,
                type: :string,
                required: true,
                description: "The starting year of the recruitment cycle.",
                example: "2020"
      parameter name: :provider_code,
                in: :path,
                type: :string,
                required: true,
                description: "The unique code of the provider.",
                example: "T92"
      parameter name: :course_code,
                in: :path,
                type: :string,
                required: true,
                description: "The code of the course.",
                example: "X130"

      response "200", "The collection of courses offered by the specified provider." do
        let(:year) { "2020" }
        let(:provider_code) { "ABC" }
        let(:course_code) { "DEF" }

        schema "$ref": "#/components/schemas/CourseSingleResponse"

        run_test!
      end
    end
  end
end
