class ApplicationController < ActionController::Base
  protect_from_forgery
  after_filter -> { expires_now if user_signed_in? }
  
  rescue_from Exception do |exception|
    begin
      if exception.kind_of? CanCan::AccessDenied
        redirect_to root_url, alert: t('errors.access_denied')
      else
        @title = t('errors.title')
        
        if response.redirect_url.blank?
          render template: 'shared/show_error', locals: { error: exception }
        end

        logger.error(([exception, ''] + exception.backtrace).join("\n"))
      end

    # In case the rescue explodes itself =)
    rescue => ex
      logger.error(([ex, ''] + ex.backtrace).join("\n"))
    end
  end
  
  def user_for_paper_trail
    current_user.try(:id)
  end
  
  private
  
  # Overwriting the sign_out redirect path method
  def after_sign_out_path_for(resource_or_scope)
    new_user_session_path
  end

  def parameterize_to_date_format(parameters = nil)
    if parameters
      from = Timeliness::Parser.parse(
        parameters[:from], :date, zone: :local
      ).to_date
      to = Timeliness::Parser.parse(
        parameters[:to], :date, zone: :local
      ).to_date
      
      { from: from, to: to }
    end
  end

  def after_sign_in_path_for(resource)
    users_path
  end
end
