#
# Description: Get Satellite Hostgroup of the given host based in its uid_ems
#
# Author: Raul Sevilla
#
# Input parameters:
# $evm.object["servername"]
# $evm.object["username"]
# $evm.object.decrypt("password")
#
######################################################3

require 'rest-client'
require 'base64'
require 'json'

# Fixed variables

$servername = $evm.object["servername"]
$username = $evm.object["username"]
$password = $evm.object.decrypt("password")
$vm = $evm.root['vm']

$headers = {
  "Accept" => "application/json",
  "Content-type" => "application/json"
}


def get_hostgroup

  $evm.log("info", "MIQ(#{__method__}) Getting hostgroup of #{$vm.name} - #{$vm.uid_ems}")
  uri = "https://#{$servername}/api/v2/hosts?search=uuid=#{$vm.uid_ems}"
  $evm.log("info", "MIQ(#{__method__}) Getting hostgroup of #{uri}")
  begin
    response = RestClient::Request.execute(
			user: $username,
			password: $password,
			method: "get",
		    url: uri,
		    headers: $headers,
			verify_ssl: false)

    $evm.log("info", "MIQ(#{__method__}) Response received: #{response.body}")
    json_data = JSON.parse(response.body)
    $evm.object["read_only"] = true
    if json_data["results"].length == 0
      $evm.log("info", "#{$vm.name} not found in Satellite")
      $evm.object["value"] = "#{$vm.name} not found in Satellite"
    else
      $evm.log("info", "#{$vm.name} found in Satellite")
      $evm.object["value"] = json_data["results"][0]["hostgroup_name"]
    end
  rescue Exception => err
    $evm.log("error", "MIQ(#{__method__}) #{err}")
    exit MIQ_ERROR
  end
end


get_hostgroup


