#
# Description: List enterprises in Nuage
#

require "rest-client"
require "json"

@value_dict  = {}
@headers     = {
  "content-type"=> "application/json",
  "x-nuage-organization" => $evm.object["organization"
}  
@api_version = $evm.object["api_version"]
@vsd_url     = "https://" + $evm.object["hostname"] + ":#{$evm.object['port']}"

def set_api_key
  api_url = "#{@vsd_url}/nuage/api/#{@api_version}/me"
  $evm.log("info", "Get API Key for user #{$evm.object['username']} from #{api_url}")
  resp = RestClient::Request.execute(
    method:     "get",
    url:        api_url,
    headers:    @headers,
    user:       $evm.object["username"],
    password:   $evm.object.decrypt("password"),
    verify_ssl: false
  )
  @api_key = JSON.parse(resp.body)[0]['APIKey']
end

def get_enterprises
  api_url = "#{@vsd_url}/nuage/api/#{@api_version}/enterprises"
  $evm.log("info", "Listing nuage enterprises from #{api_url}")
  resp = RestClient::Request.execute(
    method: "get",
    url: api_url,
    headers: @headers,
    user: $evm.object["username"],
    password: @api_key,
    :verify_ssl => false
  )
  $evm.log("info", resp.body)
  JSON.parse(resp.body).each do |e|
    @value_dict[e["ID"]] = e["name"]
  end
end

begin
  set_api_key
  get_enterprises
rescue Exception => err
  $evm.log("error", "Error: #{err}")
  @value_dict["!"] = "Error listing Nuage enterprises"
end
$evm.object["values"] = @value_dict
