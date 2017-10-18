#
# Description: List zones in a Nuage domain
#

require "rest-client"
require "json"

@value_dict   = {}
@headers      = {
  "content-type"=> "application/json",
  "x-nuage-organization" => $evm.object["organization"]
}
@api_version  = $evm.object["api_version"]
@vsd_url      = "https://" + $evm.object["hostname"] + ":#{$evm.object['port']}"
@nuage_domain = $evm.object["dialog_nuage_domain"]

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

def get_zones
  if @nuage_domain.nil?
    @value_dict["!"] = "No zones available"
  end
  api_url = "#{@vsd_url}/nuage/api/#{@api_version}/domains/#{@nuage_domain}/zones"
  $evm.log("info", "Listing nuage enterprises from #{api_url}")
  resp = RestClient::Request.execute(
    method: "get",
    url: api_url,
    headers: @headers,
    user: $evm.object["username"],
    password: @api_key,
    verify_ssl: false
  )
  $evm.log("info", resp.body)
  if resp.body.empty?
    @value_dict[""] = "No nuage zones available"
  else
    JSON.parse(resp.body).each do |z|
      @value_dict[z["ID"]] = z["name"]
    end
  end
end

begin
  set_api_key
  if @nuage_domain.nil?
    @value_dict[""] = "No nuage zones available"
  else
    get_zones
  end
rescue Exception => err
  $evm.log("error", "Error: #{err}")
  @value_dict["!"] = "Error listing Nuage zones"
end
$evm.object["values"] = @value_dict
