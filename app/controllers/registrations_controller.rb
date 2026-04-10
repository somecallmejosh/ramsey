class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]

  def new
    redirect_to root_path if authenticated?
  end

  def create
    Account.transaction do
      @account = Account.create!(name: registration_params[:account_name])
      @user = @account.users.create!(
        email_address: registration_params[:email_address],
        password: registration_params[:password],
        password_confirmation: registration_params[:password_confirmation],
        role: :owner
      )
    end

    start_new_session_for(@user)
    redirect_to root_path, notice: "Welcome to Ramsey!"
  rescue ActiveRecord::RecordInvalid => e
    flash.now[:alert] = e.record.errors.full_messages.to_sentence
    render :new, status: :unprocessable_entity
  end

  private

  def registration_params
    params.permit(:account_name, :email_address, :password, :password_confirmation)
  end
end
