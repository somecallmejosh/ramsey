module Admin
  class AccountsController < ApplicationController
    include RequireOwner

    before_action :require_owner_role

    def export
      result = AccountDataExportService.new(account: current_account).call

      if result.success?
        send_data result.csv,
                  filename: "#{current_account.name.parameterize}-data-export-#{Date.current}.csv",
                  type: "text/csv"
      else
        redirect_to admin_settings_path, alert: "Export failed. Please try again."
      end
    end

    def destroy
      account = current_account
      terminate_session
      account.destroy!
      redirect_to new_session_path, notice: "Your account has been cancelled."
    end
  end
end
