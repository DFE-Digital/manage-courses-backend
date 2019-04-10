summary 'Opt-out the provider'
usage 'optin <provider_code1 [provider_code2 ...]>'

run do |opts, args, _cmd|
  MCB.init_rails(opts)

  Provider.connection.transaction do
    args.each do |provider_code|
      provider = Provider.find_by!(provider_code: provider_code)
      verbose "updating provider #{provider_code}"
      provider.update(opted_in: false)
      provider.courses.each do |c|
        verbose "  updating course #{c.course_code}"
        c.touch(:changed_at)
      end
    end
  end
end
