name 'list'
summary 'List courses in db'

run do |opts, args, _cmd|
  MCB.init_rails(opts)

  recruitment_cycle = if opts[:recruitment_year].nil?
                        RecruitmentCycle.current_recruitment_cycle
                      else
                        RecruitmentCycle.find_by(year: opts[:recruitment_year])
                      end

  courses = recruitment_cycle.courses
  courses = courses.where(course_code: args.map(&:upcase)) if args.any?

  tp.set :capitalize_headers, false

  output = [
    '',
    'Course:',
    Tabulo::Table.new(courses) { |t|
      t.add_column :id
      t.add_column(:provider_code) { |c| c.provider.provider_code }
      t.add_column :course_code
      t.add_column :name
    }.pack(max_table_width: nil)
  ]
  MCB.pageable_output(output)
end
