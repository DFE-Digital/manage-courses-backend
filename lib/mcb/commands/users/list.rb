summary 'List users in the tb'
usage 'list [<id1> <id2> <id3>...] where id is either user email, user ID or DfE-Sign-in ID'

run do |opts, args, _cmd|
  MCB.init_rails(opts)

  users = if args.any?
            args.map { |id| MCB.find_user_by_identifier id }
          else
            User.all
          end

  tp.set :capitalize_headers, false

  puts "\nUsers:"
  puts Tabulo::Table.new(users,
                         :id,
                         :email,
                         :sign_in_user_id,
                         :first_name,
                         :last_name,
                         :last_login_date_utc).pack(max_table_width: nil)
end
