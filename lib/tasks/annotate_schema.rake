desc "Annotate models, routes and serializers"
namespace :db do
  task "schema:load" => [:annotate]
  task annotate: :environment do
    puts "Annotating routes and models..."
    system "bundle exec annotate --routes --models --show-indexes --sort"
  end
end
