module MCB
  class CoursesEditor
    LOGICAL_NAME_TO_DATABASE_NAME_MAPPING = {
      title: :name,
      route: :program_type,
      qualifications: :qualification,
      accredited_body: :accrediting_provider,
      start_date: :start_date,
      application_opening_date: :applications_open_from,
    }.freeze

    def initialize(provider:, requester:, course_codes: [])
      @cli = CoursesEditorCLI.new(provider)

      @provider = provider
      @requester = requester
      @courses = course_codes.present? ? find_courses(provider, course_codes) : provider.courses

      check_authorisation
    end

    def run
      finished = false
      puts "Editing #{course_codes.join(', ')}"
      print_at_most_two_courses
      until finished
        choice = main_loop

        if choice.nil?
          finished = true
        elsif choice.start_with?("edit")
          attribute = choice.gsub("edit ", "").gsub(" ", "_").to_sym
          edit(attribute)
        elsif choice =~ /sync .* to Find/
          sync_courses_to_find
        end
      end
    end

  private

    def main_loop
      choices = [
        "edit title",
        "edit course code",
        "edit maths",
        "edit english",
        "edit science",
        "edit route",
        "edit qualifications",
        "edit study mode",
        "edit accredited body",
        "edit start date",
        "edit application opening date",
        "edit age range",
        "sync course(s) to Find"
      ]
      @cli.ask_multiple_choice(prompt: "What would you like to edit?", choices: choices)
    end

    def edit(logical_attribute)
      database_attribute = LOGICAL_NAME_TO_DATABASE_NAME_MAPPING[logical_attribute] || logical_attribute
      print_existing(database_attribute)
      user_response_from_cli = @cli.send("ask_#{logical_attribute}".to_sym)
      unless user_response_from_cli.nil?
        update(database_attribute => user_response_from_cli)
      end
    end

    def check_authorisation
      @courses.each { |course| raise Pundit::NotAuthorizedError unless can_update?(course) }
    end

    def print_at_most_two_courses
      @courses.take(2).each { |course| puts MCB::Render::ActiveRecord.course(course) }
      puts "Only showing first 2 courses" if @courses.size > 2
    end

    def print_existing(attribute_name)
      puts "Existing values for course #{attribute_name}:"
      table = Tabulo::Table.new @courses.order(:course_code) do |t|
        t.add_column(:course_code, header: "course\ncode", width: 4)
        t.add_column(attribute_name) unless attribute_name == :course_code
      end
      puts table.pack(max_table_width: nil), table.horizontal_rule
    end

    def update(attrs)
      @courses.each { |course| course.update(attrs) }
    end

    def can_update?(course)
      CoursePolicy.new(@requester, course).update?
    end

    def sync_courses_to_find
      @courses.each do |course|
        ManageCoursesAPIService::Request.sync_course_with_search_and_compare(
          @requester.email,
          @provider.provider_code,
          course.course_code
        )
      end
    end

    def course_codes
      @courses.order(:course_code).pluck(:course_code)
    end

    def find_courses(provider, course_codes)
      courses = provider.courses.where(course_code: course_codes)
      missing_course_codes = course_codes - courses.pluck(:course_code)
      raise ArgumentError, "Couldn't find course " + missing_course_codes.join(", ") unless missing_course_codes.empty?

      courses
    end
  end
end
