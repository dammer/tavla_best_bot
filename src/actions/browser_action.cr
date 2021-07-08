abstract class BrowserAction < Lucky::Action
  # include Lucky::ProtectFromForgery
  accepted_formats [:html, :json], default: :html
  disable_cookies

  before log_params

  private def log_params
    Log.info { "params: #{params.to_h}" }
    continue
  end
end
