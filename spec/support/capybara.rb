require "capybara/rspec"

# Chrome 146 headless: WebDriver Element Click intermittently never reaches the
# page (no pointer or click events), and typed keys are sometimes lost. Capybara
# still finds elements the normal way (visible, enabled); only the final
# click / value entry goes through JS so specs test the app, not the driver.
Capybara::Selenium::Node.prepend(Module.new do
  JS_SET_TYPES = %w[number text email password search tel url].freeze

  def set(value, **options)
    input_type = (tag_name == "input") ? (native.attribute("type") || "text") : nil
    if input_type == "checkbox"
      driver.execute_script("arguments[0].click()", native) if value != checked?
    elsif JS_SET_TYPES.include?(input_type) || tag_name == "textarea"
      driver.execute_script(<<~JS, native, value.to_s)
        const el = arguments[0]
        el.focus()
        el.value = arguments[1]
        el.dispatchEvent(new Event("input", { bubbles: true }))
        el.dispatchEvent(new Event("change", { bubbles: true }))
      JS
    else
      super
    end
  rescue Selenium::WebDriver::Error::WebDriverError
    super
  end

  def click(keys = [], **options)
    return super if keys.any? || options[:x] || options[:y]

    driver.execute_script("arguments[0].click()", native)
  end
end)

Capybara.register_driver :selenium_chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument("--headless=new")
  options.add_argument("--no-sandbox")
  options.add_argument("--disable-dev-shm-usage")
  options.add_argument("--window-size=1400,900")
  # Block notification permission so the push prompt Stimulus controller removes itself.
  # Without this, Notification.permission === "default" and the modal renders/interferes.
  options.add_preference("profile.default_content_setting_values.notifications", 2)
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
