#
# Description: Creates a subnet in nuage
#

require "rest-client"
require "json"

@value_dict  = {}
@headers     = {
  "content-type"=> "application/json",
  "x-nuage-organization" => $evm.object["organization"]
}
@api_version = $evm.object["api_version"]
@vsd_url     = "https://" + $evm.object["hostname"] + ":#{$evm.object['port']}"
@nuage_zone  = $evm.root["dialog_nuage_zone"]
@name        = $evm.root["dialog_name"]
@address     = $evm.root["dialog_address"]
@netmask     = $evm.root["dialog_netmask"]
@gateway     = $evm.root["dialog_gateway"]


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

def create_subnet
  payload = {
    "name"    => @name,
    "address" => @address,
    "netmask" => @netmask,
    "gateway" => @gateway
  }
  api_url = "#{@vsd_url}/nuage/api/#{@api_version}/zones/#{@nuage_zone}/subnets"
  $evm.log("info", "Creating nuage subnet in through the endpoint #{api_url}")
  $evm.log("info", "Payload: #{payload}")
  resp = RestClient::Request.execute(
    method: "post",
    url: api_url,
    headers: @headers,
    payload: payload.to_json,
    user: $evm.object["username"],
    password: @api_key,
    verify_ssl: false
  )
end

begin
  set_api_key
  subnet = JSON.parse(create_subnet)[0]
  $evm.set_state_var("nuagenet", subnet["ID"])
  $evm.log("info", "Subnet #{@name} successfully created")
rescue Exception => err
  $evm.log("error", "Error: #{err}")
  exit MIQ_ABORT
end


