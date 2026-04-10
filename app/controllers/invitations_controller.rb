class InvitationsController < ApplicationController
  include RequireOwner

  before_action :require_owner_role

  def index
    @invitations = current_account.invitations.pending.order(created_at: :desc)
  end

  def create
    @invitation = current_account.invitations.build(
      invited_by: current_user,
      email: params[:email],
      expires_at: 7.days.from_now
    )

    if @invitation.save
      redirect_to invitations_path, notice: "Invitation created."
    else
      @invitations = current_account.invitations.pending.order(created_at: :desc)
      flash.now[:alert] = @invitation.errors.full_messages.to_sentence
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    invitation = current_account.invitations.find(params[:id])
    invitation.destroy
    redirect_to invitations_path, notice: "Invitation revoked."
  end
end
