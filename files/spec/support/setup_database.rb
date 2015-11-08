SeedFu.quiet = true

RSpec.configure do |config|
  config.before :suite do
    DatabaseRewinder.clean_all
    SeedFu.seed(SeedFu.fixture_paths)
  end

  config.after :each do
    DatabaseRewinder.clean
  end
end
