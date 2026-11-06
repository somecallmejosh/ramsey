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
        redirect_to admin_settings_path, alert: "The download didn't work. Please try again in a minute."
      end
    end

    def destroy
      account = current_account
      unless params[:confirm_name].to_s.strip.casecmp?(account.name.strip)
        return redirect_to admin_settings_path,
          alert: "Nothing was deleted. Type the household name exactly as shown to confirm."
      end

      terminate_session
      account.destroy!
      redirect_to new_session_path, notice: "#{account.name} and all its data have been deleted."
    end
  end
end
