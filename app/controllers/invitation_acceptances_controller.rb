class InvitationAcceptancesController < ApplicationController
  allow_unauthenticated_access only: %i[new create]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to accept_invitation_path(token: params[:token]), alert: "Too many tries. Please wait a few minutes and try again." }

  before_action :set_invitation

  def new
  end

  def create
    @user = @invitation.account.users.build(
      email_address: params[:email_address],
      password: params[:password],
      password_confirmation: params[:password_confirmation],
      role: :member
    )

    User.transaction do
      @user.save!
      @invitation.update!(accepted_at: Time.current)
    end

    start_new_session_for(@user)
    redirect_to root_path, notice: "Welcome to #{@invitation.account.name}!"
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_entity
  end

  private

  # The pending scope already excludes expired and accepted invites.
  def set_invitation
    @invitation = Invitation.pending.find_by(token: params[:token])
    render :invalid, status: :gone unless @invitation
  end
end
