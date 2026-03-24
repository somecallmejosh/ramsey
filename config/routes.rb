Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token

  get "up" => "rails/health#show", as: :rails_health_check
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "dashboard#index"

  # Envelope dashboard and detail
  resources :envelopes, only: [:new, :create, :edit, :update] do
    resources :expenses, only: [:new, :create, :destroy]
    resources :envelope_budgets, only: [:edit, :update], shallow: true
  end

  # Admin settings
  namespace :admin do
    resource :settings, only: [:show]
    resources :envelopes, only: [:index, :new, :create, :edit, :update]
  end

  # Dashboard with month selector
  get "dashboard(/:year/:month)", to: "dashboard#index", as: :dashboard,
      constraints: { year: /\d{4}/, month: /\d{1,2}/ }

  # Cron endpoints
  scope :cron do
    post "monthly_rollover",          to: "cron#monthly_rollover",          as: :cron_monthly_rollover
    post "purge_unconfirmed_meal_plans", to: "cron#purge_unconfirmed_meal_plans", as: :cron_purge_meal_plans
  end
end
