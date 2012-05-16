module SafetyMailer
  class Carrier
    attr_accessor :matchers, :settings, :forward_to

    def initialize(params = {})
      self.matchers   = params[:allowed_matchers] || []
      self.forward_to = params[:forward_to] || []
      self.settings   = params[:delivery_method_settings] || {}
      delivery_method = params[:delivery_method] || :smtp
      @delivery_method = Mail::Configuration.instance.lookup_delivery_method(delivery_method).new(settings)
    end

    def log(msg)
      Rails.logger.warn(msg) if defined?(Rails)
    end

    def deliver!(mail)
      if ENV['DISABLE_SAFETY_MAILER'] == 'true'
        @delivery_method.deliver!(mail)
      else
        allowed_emails = mail.to.select do |recipient|
          matchers.any?{ |m| recipient =~ m }
        end

        mail.to = allowed_emails
        mail.to += forward_to if forward_to.any?

        if mail.to.nil? || mail.to.empty?
          log "*** safety_mailer - no recipients left ... suppressing delivery altogether"
        else
          log "*** safety_mailer allowing delivery to #{mail.to}"
          @delivery_method.deliver!(mail)
        end
      end
    end
  end
end
