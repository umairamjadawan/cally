Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Root route - main chat interface
  root 'chat#index'
  
  # API routes for chat functionality
  post '/chat', to: 'chat#send_message'
  get '/chat/history', to: 'chat#history'
  delete '/chat/clear', to: 'chat#clear_history'
  
  # Settings routes for parental configuration
  get '/settings', to: 'settings#index'
  patch '/settings', to: 'settings#update'
  post '/settings/reset', to: 'settings#reset_to_defaults', as: :reset_settings
  get '/settings/test_prompt', to: 'settings#test_prompt'
  
  # Health check
  get '/health', to: 'application#health'
  
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end