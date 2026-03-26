Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token

  get "up" => "rails/health#show", as: :rails_health_check
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "dashboard#index"

  # Envelope dashboard and detail
  resources :envelopes, only: [ :new, :create, :edit, :update ] do
    resources :expenses, only: [ :index, :new, :create, :destroy ]
    resources :envelope_budgets, only: [ :edit, :update ], shallow: true
  end

  # Debt snowball
  resources :debts, only: [ :index, :show ] do
    resources :debt_payments, only: [ :new, :create, :destroy ]
  end

  # Admin settings
  namespace :admin do
    resource :settings, only: [ :show, :update ]
    resources :envelopes, only: [ :index, :new, :create, :edit, :update ] do
      member do
        patch :deactivate
        patch :reactivate
      end
    end
    resources :debts, only: [ :new, :create, :edit, :update ]
  end

  # Dashboard with month selector
  get "dashboard(/:year/:month)", to: "dashboard#index", as: :dashboard,
      constraints: { year: /\d{4}/, month: /\d{1,2}/ }

  # Meal planner
  resources :meal_plans, only: [ :new, :create, :show, :destroy ] do
    member do
      patch :confirm
    end
  end
  resources :shopping_items, only: [ :create, :update, :destroy ]

  # Lunch tracker
  resources :lunch_logs, only: [ :index, :create, :destroy ]

  # Cron endpoints
  scope :cron do
    post "monthly_rollover",          to: "cron#monthly_rollover",          as: :cron_monthly_rollover
    post "purge_unconfirmed_meal_plans", to: "cron#purge_unconfirmed_meal_plans", as: :cron_purge_meal_plans
  end
end
