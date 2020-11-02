Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  use_doorkeeper do
    # it accepts :authorizations, :tokens, :token_info, :applications and :authorized_applications
    skip_controllers :applications, :authorized_applications
  end

  namespace :api do
    resources :competency_frameworks, only: [:show], constraints: { :id => /.*/ } do
      member do
        get :asset_file
      end

      collection do
        get :search
      end
    end
  end
end
