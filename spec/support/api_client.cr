class ApiClient < Lucky::BaseHTTPClient
  def initialize
    super
    headers("Content-Type": "application/json")
  end

  def exec(route_helper : Lucky::RouteHelper, params : NamedTuple) : HTTP::Client::Response
    @client.exec(
      method: route_helper.method.to_s.upcase,
      path: route_helper.path,
      body: params.fetch(:raw_body, params.to_json)
    )
  end
end
