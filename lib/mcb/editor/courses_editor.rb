module MCB
  module Editor
    class CoursesEditor < MCB::Editor::Base
      LOGICAL_NAME_TO_DATABASE_NAME_MAPPING = {
        title: :name,
        route: :program_type,
        qualifications: :qualification,
        accredited_body: :accrediting_provider,
        start_date: :start_date,
        application_opening_date: :applications_open_from,
        is_send: :is_send,
      }.freeze

      def initialize(provider:, requester:, course_codes: [], courses: nil)
        @courses = courses || load_courses(provider, course_codes)
        super(provider: provider, requester: requester)
      end

      def run
        finished = false
        until finished
          course_codes = @courses.order(:course_code).pluck(:course_code)
          puts "Editing #{course_codes.join(', ')}"
          print_at_most_two_courses
          choice = main_loop

          if choice.nil?
            finished = true
          else
            perform_action(choice)
          end
        end
      end

      def new_course_wizard
        %i[title qualifications study_mode accredited_body start_date route maths
           english science age_range_in_years level course_code is_send].each do |attribute|
          edit(attribute)
        end

        course.subjects = @cli.multiselect(
          initial_items: course.subjects.to_a,
          possible_items: course.assignable_subjects,
        )
        course.ensure_modern_languages
        puts "\nAbout to create the following course:"
        print_at_most_two_courses
        if @cli.confirm_creation? && try_saving_course
          edit_sites
          edit(:application_opening_date)
          print_summary
        else
          puts "Aborting"
        end
      end

    protected

      def setup_cli
        @cli = MCB::Cli::CourseCli.new(@provider)
      end

      def check_authorisation
        @courses.each { |course| raise Pundit::NotAuthorizedError unless can_update?(course) }
      end

    private

      def main_loop
        choices = [
          "edit title",
          "edit course code",
          "sync course(s) to Find",
        ]
        @cli.ask_multiple_choice(prompt: "What would you like to edit?", choices: choices)
      end

      def perform_action(choice)
        if choice.start_with?("edit")
          attribute = choice.gsub("edit ", "").gsub(" ", "_").downcase.to_sym
          edit(attribute)
        elsif choice =~ /sync .* to Find/
          sync_courses_to_find
        end
      end

      def edit(logical_attribute)
        database_attribute = LOGICAL_NAME_TO_DATABASE_NAME_MAPPING[logical_attribute] || logical_attribute
        print_existing(database_attribute)
        user_response_from_cli = @cli.send("ask_#{logical_attribute}".to_sym)
        unless user_response_from_cli.nil?
          update(database_attribute => user_response_from_cli)
        end
      end

      def edit_subjects
        course.subjects = @cli.multiselect(
          initial_items: course.subjects.to_a,
          possible_items: course.assignable_subjects,
        )
        course.reload
      end

      def edit_study_mode
        edit(:study_mode)
        course.ensure_site_statuses_match_study_mode if course.study_mode_previously_changed?
      end

      def edit_sites
        course.sites = @cli.multiselect(
          initial_items: course.sites.to_a,
          possible_items: @provider.sites,
        )
        course.reload
      end

      def load_courses(provider, course_codes)
        (course_codes.present? ? find_courses(provider, course_codes) : provider.courses).
          order(:course_code)
      end

      def course
        if @courses.count != 1
          raise ArgumentError, "Cannot do this operation when there are multiple courses"
        end

        @courses.first
      end

      def print_at_most_two_courses
        @courses.take(2).each { |course| puts MCB::Render::ActiveRecord.course(course) }
        puts "Only showing first 2 courses" if @courses.size > 2
      end

      def print_existing(attribute_name)
        # don't print the existing attributes when creating a new course, since
        # this will be null in the majority of cases
        if @courses.select(&:persisted?).all?
          puts "Existing values for course #{attribute_name}:"
          table = Tabulo::Table.new @courses do |t|
            t.add_column(:course_code, header: "course\ncode", width: 4)
            t.add_column(attribute_name) unless attribute_name == :course_code
          end
          puts table.pack(max_table_width: nil), table.horizontal_rule
        end
      end

      def print_summary
        puts "\nHere's the final course that's been created:"
        print_at_most_two_courses
        @cli.enter_to_continue
      end

      def try_saving_course
        if course.valid?
          puts "Saving the course"
          course.save!
          true
        else
          puts "Course isn't valid:"
          course.errors.full_messages.each { |error| puts " - #{error}" }
          false
        end
      end

      def update(attrs)
        @courses.each do |course|
          if course.new_record?
            attrs.each { |key, value| course.send("#{key}=".to_sym, value) }
          else
            course.update(attrs)
          end
        end
      end

      def can_update?(course)
        CoursePolicy.new(@requester, course).update?
      end

      def sync_courses_to_find
        request = SyncCoursesToFindJob.new
        request.perform(*@courses)
      end

      def find_courses(provider, course_codes)
        courses = provider.courses.where(course_code: course_codes)
        missing_course_codes = course_codes - courses.pluck(:course_code)
        raise ArgumentError, "Couldn't find course " + missing_course_codes.join(", ") unless missing_course_codes.empty?

        courses
      end
    end
  end
end
