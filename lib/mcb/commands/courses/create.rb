summary 'Create a new course in db'
usage 'create <provider_code>'
param :provider_code, transform: ->(code) { code.upcase }

run do |opts, args, _cmd|
  MCB.init_rails(opts)

  Course.connection.transaction do
    provider = RecruitmentCycle.current_recruitment_cycle.providers.find_by!(provider_code: args[:provider_code])
    requester = User.find_by!(email: MCB.config[:email])

    MCB::CoursesEditor.new(
      provider: provider,
      requester: requester,
      courses: [provider.courses.build]
    ).new_course_wizard
  end
end
