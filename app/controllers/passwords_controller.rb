class PasswordsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_user_by_token, only: %i[ edit update ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_password_path, alert: "Too many tries. Please wait a few minutes and try again." }

  def new
  end

  def create
    if user = User.find_by(email_address: params[:email_address])
      PasswordsMailer.reset(user).deliver_later
    end

    # Shown as a lasting message on the sign-in page (not a brief toast)
    # so nobody misses the "check your inbox" step.
    redirect_to new_session_path, flash: { reset_sent: true }
  end

  def edit
  end

  def update
    if params[:password].blank?
      # has_secure_password ignores a blank password on update, which
      # would otherwise "succeed" without changing anything.
      @user.errors.add(:password, :blank)
    elsif @user.update(params.permit(:password, :password_confirmation))
      @user.sessions.destroy_all
      redirect_to new_session_path, notice: "Your password has been changed. Sign in with your new password."
      return
    end

    render :edit, status: :unprocessable_entity
  end

  private
    def set_user_by_token
      @user = User.find_by_password_reset_token!(params[:token])
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      redirect_to new_password_path, alert: "That reset link has expired or was already used. Enter your email to get a new one."
    end
end
