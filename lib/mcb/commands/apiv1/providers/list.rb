name "list"
summary "List providers"

option :P, "max-pages", "maximum number of pages to request",
       default: 1,
       argument: :required,
       transform: method(:Integer)

run do |opts, _args, _cmd|
  MCB.init_rails(opts)

  opts = MCB.apiv1_opts(opts)
  last_context = nil

  opts = MCB.expose_opts_defaults_for_splat(opts, :url, :"max-pages", :token, :all)

  table = Terminal::Table.new headings: %w[Code Name] do |t|
    MCB.each_v1_provider(opts).each do |provider, context|
      last_context = context
      t << provider.slice("institution_code", "institution_name").values
    end
  end

  puts table

  MCB::display_pages_received(page: last_context[:page],
                              max_pages: opts[:"max-pages"],
                              next_url: last_context[:next_url])
end
