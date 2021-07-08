class Home::Index < BrowserAction
  get "/" do
    # TODO: html Lucky::WelcomePage
    head status: 404
  end
end
