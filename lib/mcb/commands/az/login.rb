name "login"
summary "run az login"

run do |_opts, _args, _cmd|
  system("az login")
end
