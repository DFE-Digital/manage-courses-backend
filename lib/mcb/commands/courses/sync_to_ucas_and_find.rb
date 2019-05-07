name 'sync-to-ucas-and-find'
summary 'Sync a course with Find and send to UCAS'
usage 'sync-to-ucas-and-find <provider_code> <course_code>'
param :provider_code
param :course_code

run do |opts, args, _cmd|
  MCB.init_rails(opts)

  Provider.connection.transaction do
    provider = Provider.find_by!(provider_code: args[:provider_code])
    course = Course.find_by!(provider: provider, course_code: args[:course_code])
    user = User.find_by!(email: MCB.config[:email])

    ManageCoursesAPIService::Request.sync_course_with_search_and_compare(
      MCB.config[:email],
      args[:provider_code],
      args[:course_code]
    )
    course.send :touch_course
  end
end
