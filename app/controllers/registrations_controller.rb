class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_registration_path, alert: "Too many tries. Please wait a few minutes and try again." }

  def new
    redirect_to root_path if authenticated?
  end

  def create
    @account = Account.new(name: registration_params[:account_name])
    @user = User.new(
      account: @account,
      email_address: registration_params[:email_address],
      password: registration_params[:password],
      password_confirmation: registration_params[:password_confirmation],
      role: :owner
    )

    # Validate both so every problem shows at once, not one per attempt.
    if [ @account.valid?, @user.valid? ].all?
      Account.transaction do
        @account.save!
        @user.save!
      end
      start_new_session_for(@user)
      redirect_to root_path, notice: "Welcome to Clempo!"
    else
      render :new, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_entity
  end

  private

  def registration_params
    params.permit(:account_name, :email_address, :password, :password_confirmation)
  end
end
