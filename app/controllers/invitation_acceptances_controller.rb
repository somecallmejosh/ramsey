class InvitationAcceptancesController < ApplicationController
  allow_unauthenticated_access only: %i[new create]

  before_action :set_invitation

  def new
    redirect_to root_path, alert: "This invitation has expired." if @invitation.expired?
  end

  def create
    if @invitation.expired?
      redirect_to root_path, alert: "This invitation has expired." and return
    end

    @user = @invitation.account.users.create!(
      email_address: params[:email_address],
      password: params[:password],
      password_confirmation: params[:password_confirmation],
      role: :member
    )
    @invitation.update!(accepted_at: Time.current)

    start_new_session_for(@user)
    redirect_to root_path, notice: "Welcome to #{@invitation.account.name}!"
  rescue ActiveRecord::RecordInvalid => e
    flash.now[:alert] = e.record.errors.full_messages.to_sentence
    render :new, status: :unprocessable_entity
  end

  private

  def set_invitation
    @invitation = Invitation.pending.find_by!(token: params[:token])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Invalid or expired invitation."
  end
end
