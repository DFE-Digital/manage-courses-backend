name 'find'
summary 'Find a particular provider entry'
usage 'find [options] <code>'
param :code

run do |opts, args, _cmd|
  puts "looking for provider #{args[:code]}"

  provider = each_v1_provider(opts).detect do |p|
    p['institution_code'] == args[:code]
  end

  if provider.nil?
    error "Provider with code '#{args[:code]}' not found"
    next
  end

  campuses = provider.delete('campuses')
  puts Terminal::Table.new rows: provider
  puts ''
  puts "Campuses:"
  tp campuses
end
