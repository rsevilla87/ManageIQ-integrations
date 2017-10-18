#
# Description: List domains in a Nuage enterprise
#

require "rest-client"
require "json"

@value_dict       = {}
@headers          = {
  "content-type" => "application/json",
  "x-nuage-organization" => $evm.object["organization"]
}
@api_version      = $evm.object["api_version"]
@vsd_url          = "https://" + $evm.object["hostname"] + ":#{$evm.object['port']}"
@nuage_enterprise = $evm.object["dialog_nuage_enterprise"]

def set_api_key
  api_url = "#{@vsd_url}/nuage/api/#{@api_version}/me"
  $evm.log("info", "Get API Key for user #{$evm.object['username']} from #{api_url}")
  resp = RestClient::Request.execute(
    method: "get",
    url: api_url,
    headers: @headers,
    user: $evm.object["username"],
    password: $evm.object.decrypt("password"),
    verify_ssl: false
  )
  @api_key = JSON.parse(resp.body)[0]['APIKey']
end

def get_domains
  if @nuage_enterprise.nil?
    @value_dict["!"] = "No domains available"
  end
  api_url = "#{@vsd_url}/nuage/api/#{@api_version}/enterprises/#{@nuage_enterprise}/domains"
  $evm.log("info", "Listing nuage enterprises from #{api_url}")
  resp = RestClient::Request.execute(
    method: "get",
    url: api_url,
    headers: @headers,
    user: $evm.object["username"],
    password: @api_key,
    verify_ssl:  false
  )
  $evm.log("info", resp.body)
  if resp.body.empty?
    $evm.log("info", "No domains available in enterprise #{@nuage_enterprise}")
    @value_dict[""] = "No domains available in enterprise"
  else
    JSON.parse(resp.body).each do |d|
      @value_dict[d["ID"]] = d["name"]
    end
  end
end

begin
  set_api_key
  get_domains
  unless @nuage_enterprise.nil?
    get_domains
  end
  
rescue Exception => err
  $evm.log("error", "Error: #{err}")
  @value_dict["!"] = "Error listing Nuage domains"
end
$evm.object["values"] = @value_dict
