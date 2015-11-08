def remove_comments(filepath)
  gsub_file filepath, /^\s*#.*\n/, ''
end

# 差分をわかりやすくするため一旦コミット
rails_new_str = ['rails', *ARGV].join(' ')
git :init
git add: '.'
git commit: "-m '#{rails_new_str}'"

turbolinks_on = yes? 'Use turbolinks? (y/n)'

# Gemfile
#-------------------------------------------------
comment_lines 'Gemfile', /turbolinks/ unless turbolinks_on
comment_lines 'Gemfile', /sdoc/
remove_comments 'Gemfile'

gem 'draper'
gem 'enumerize'
gem 'seed-fu'
gem 'slim-rails'

# NOTE: railsのmasterではadd_sourceでブロックの記述が可能になっている
append_file 'Gemfile', <<RUBY.strip_heredoc

  source 'https://rails-assets.org' do
    gem 'rails-assets-vue'
    gem 'rails-assets-dispatcher'
    gem 'rails-assets-fontawesome'
    gem 'rails-assets-bootstrap-sass-official'
  end
RUBY

gem_group :development do
  # gem 'better_errors'
  # gem 'binding_of_caller'
  gem 'bullet'
  gem 'slim_lint', require: false
  gem 'html2slim', require: false
  gem 'quiet_assets'
  gem 'rubocop', require: false
end

gem_group :development, :test do
  gem 'awesome_print'
  gem 'factory_girl_rails'
  gem 'hirb'
  gem 'hirb-unicode'
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'rspec-rails', '~> 3.0'
end

gem_group :test do
  gem 'capybara'
  gem 'database_rewinder'
  gem 'launchy'
  gem 'poltergeist'
end

run 'bundle install --jobs=4' if yes?('Run bundle install now? (y/n)')

# Configs
#-------------------------------------------------
application 'config.autoload_paths += Dir["#{config.root}/lib/**/"]'
application "config.time_zone = 'Asia/Tokyo'"
application 'config.active_record.default_timezone = :local'
application 'config.i18n.default_locale = :ja'
application 'config.sass.preferred_syntax = :sass'
application <<RUBY.strip_heredoc
  config.generators do |g|
    g.assets false
    g.helper false
    g.jbuilder false
    g.controller_specs false
    g.helper_specs false
    g.request_specs false
    g.routing_specs false
    g.view_specs false
  end
RUBY

environment <<RUBY.strip_heredoc, env: 'development'
  config.after_initialize do
    Bullet.enable = true
    Bullet.alert = true
    Bullet.console = true
    Bullet.rails_logger = true
    Bullet.bullet_logger = true
  end
RUBY

# Generated files
#-------------------------------------------------
remove_file 'README.rdoc'
create_file 'README.md', <<-README.strip_heredoc
  # #{app_name}

  This README would normally document whatever steps are necessary to get the
  application up and running.

  Things you may want to cover:

  * Ruby version
  * System dependencies
  * Configuration
  * Database creation
  * Database initialization
  * How to run the test suite
  * Services (job queues, cache servers, search engines, etc.)
  * Deployment instructions
  * ...
README

if yes? 'Download default locales? (y/n)'
  remove_file 'config/locales/en.yml'
  run 'curl -L http://raw.github.com/svenfuchs/rails-i18n/master/rails/locale/en.yml -o config/locales/en.yml'
  run 'curl -L http://raw.github.com/svenfuchs/rails-i18n/master/rails/locale/ja.yml -o config/locales/ja.yml'
end

remove_file 'db/seeds.rb'
remove_comments 'config/routes.rb'

# Assets
#-------------------------------------------------
run 'bundle exec erb2slim -d app/views'

# goodbye turbolinks
unless turbolinks_on
  gsub_file 'app/assets/javascripts/application.js', /^.*turbolinks.*\n/, ''
  gsub_file 'app/views/layouts/application.html.slim', ", 'data-turbolinks-track' => true", ''
end

# RSpec
#-------------------------------------------------
generate 'rspec:install'
run 'bundle binstubs rspec-core'

insert_into_file 'spec/spec_helper.rb', <<RUBY, after: "RSpec.configure do |config|\n"
  config.example_status_persistence_file_path = "./spec/examples.txt"

  config.define_derived_metadata do |meta|
    meta[:aggregate_failures] = true unless meta.key?(:aggregate_failures)
  end

RUBY

insert_into_file 'spec/rails_helper.rb', <<RUBY.strip_heredoc, after: "require 'rspec/rails'\n"
  require 'capybara/rspec'
  require 'capybara/poltergeist'
  Capybara.javascript_driver = :poltergeist
RUBY

insert_into_file 'spec/rails_helper.rb', <<RUBY, after: "RSpec.configure do |config|\n"
  config.include ActiveSupport::Testing::TimeHelpers
RUBY

uncomment_lines 'spec/rails_helper.rb', "Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }"

empty_directory 'spec/support'
run 'curl -L https://raw.githubusercontent.com/upinetree/rails_template/master/files/spec/support/factory_girl.rb -o spec/support/factory_girl.rb'
run 'curl -L https://raw.githubusercontent.com/upinetree/rails_template/master/files/spec/support/setup_database.rb -o spec/support/setup_database.rb'

remove_comments 'spec/spec_helper.rb'
remove_comments 'spec/rails_helper.rb'

# Run
#-------------------------------------------------
rake 'db:create db:migrate'
