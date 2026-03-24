require "capybara/rspec"

# Chrome 146 headless: WebDriver Element Click does not fire JS events on checkboxes,
# and input.select() is invalid for number inputs, causing set() to silently fail.
# Patch to use JS for checkboxes and number inputs.
Capybara::Selenium::Node.prepend(Module.new do
  def set(value, **options)
    input_type = (tag_name == "input") ? native.attribute("type") : nil
    case input_type
    when "checkbox"
      driver.execute_script("arguments[0].click()", native) if value != checked?
    when "number"
      driver.execute_script("arguments[0].value = arguments[1]", native, value.to_s)
      driver.execute_script("arguments[0].dispatchEvent(new Event('input', {bubbles:true}))", native)
      driver.execute_script("arguments[0].dispatchEvent(new Event('change', {bubbles:true}))", native)
    else
      super
    end
  rescue
    super
  end
end)

Capybara.register_driver :selenium_chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument("--headless=new")
  options.add_argument("--no-sandbox")
  options.add_argument("--disable-dev-shm-usage")
  options.add_argument("--window-size=1400,900")
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Capybara.default_driver    = :rack_test
Capybara.javascript_driver = :selenium_chrome_headless
Capybara.default_max_wait_time = 5

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :selenium_chrome_headless
  end

  config.after(:each, type: :system) do |example|
    if example.exception
      begin
        logs = page.driver.browser.logs.get(:browser)
        if logs.any?
          puts "\n--- Browser console logs for '#{example.description}' ---"
          logs.each { |log| puts "  [#{log.level}] #{log.message}" }
          puts "---"
        end
      rescue
        # log capture not supported
      end
    end
    # Quit Chrome after each test so the next test gets a fresh browser with no state
    page.driver.quit rescue nil
  end
end
