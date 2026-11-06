# Lets any signed-in user change their own password. (Forgotten passwords
# go through PasswordsController's emailed reset link instead.)
class AccountPasswordsController < ApplicationController
  rate_limit to: 10, within: 3.minutes, only: :update,
             with: -> { redirect_to edit_account_password_path, alert: "Too many tries. Please wait a few minutes and try again." }

  def edit
    @user = current_user
  end

  def update
    @user = current_user

    if !@user.authenticate(params[:current_password].to_s)
      @user.errors.add(:current_password, "is incorrect")
    elsif params[:password].blank?
      # has_secure_password ignores a blank password on update, which
      # would otherwise "succeed" without changing anything.
      @user.errors.add(:password, :blank)
    elsif @user.update(params.permit(:password, :password_confirmation))
      # Sign out everywhere else, in case the old password was compromised.
      @user.sessions.where.not(id: Current.session.id).destroy_all
      redirect_to admin_settings_path, notice: "Your password has been changed."
      return
    end

    render :edit, status: :unprocessable_entity
  end
end
