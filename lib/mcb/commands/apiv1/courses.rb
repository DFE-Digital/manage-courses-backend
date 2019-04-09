name 'course'
summary 'Operate on courses via the V1 API'
default_subcommand 'list'

option :a, :all, 'Perform on all courses, not just the first page returned.',
       default: false
option :c, :'changed-since', 'Perform only on providers changed since this date',
       argument: :required
option :e, :endpoint, 'Path to the endpoint to use for providers',
       argument: :required,
       default: '/api/v1/2019/courses'
