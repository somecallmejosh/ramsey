# Be sure to restart your server when you modify this file.

# Add the builds directory so Propshaft serves compiled Tailwind CSS
Rails.application.config.assets.paths << Rails.root.join("app/assets/builds")
