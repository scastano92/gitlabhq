require 'gitlab/current_settings'
include Gitlab::CurrentSettings

if Rails.env.production? && current_application_settings.sentry_enabled
  uri = URI.parse(current_application_settings.sentry_dsn)
  CSP_REPORT_URI = "#{uri.scheme}://#{uri.host}/api#{uri.path}/csp-report/?sentry_key=#{uri.user}"
else
  CSP_REPORT_URI = ''
end

SecureHeaders::Configuration.default do |config|
  config.cookies = {
    secure: true, # mark all cookies as "Secure"
    httponly: true, # mark all cookies as "HttpOnly"
    samesite: {
      strict: true # mark all cookies as SameSite=Strict
    }
  }
  config.x_frame_options = "DENY"
  config.x_content_type_options = "nosniff"
  config.x_xss_protection = "1; mode=block"
  config.x_download_options = "noopen"
  config.x_permitted_cross_domain_policies = "none"
  config.referrer_policy = "origin-when-cross-origin"
  config.csp = {
    # "meta" values. these will shaped the header, but the values are not included in the header.
    report_only: true,      # default: false
    preserve_schemes: true, # default: false. Schemes are removed from host sources to save bytes and discourage mixed content.

    # directive values: these values will directly translate into source directives
    default_src: %w('none'),
    frame_src: %w('self'),
    connect_src: %w('self'),
    font_src: %w('self'),
    img_src: %w('self' www.gravatar.com secure.gravatar.com https:),
    media_src: %w('none'),
    object_src: %w('none'),
    script_src: %w('unsafe-inline' 'self'),
    style_src: %w('unsafe-inline' 'self'),
    base_uri: %w('self'),
    child_src: %w('self'),
    form_action: %w('self'),
    frame_ancestors: %w('none'),
    block_all_mixed_content: true, # see http://www.w3.org/TR/mixed-content/
    upgrade_insecure_requests: true, # see https://www.w3.org/TR/upgrade-insecure-requests/
    report_uri: %W(#{CSP_REPORT_URI})
  }

  if Rails.env.development?
    config.csp[:script_src] << "maxcdn.bootstrapcdn.com"
  end
end

SecureHeaders::Configuration.override(:background_jobs) do |config|
  config.csp[:frame_ancestors] = %w('self')
  config.x_frame_options = 'SAMEORIGIN'
end
