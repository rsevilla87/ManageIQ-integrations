#
# Description: Apply puppet class in a given host and wait for it to finish
#
# Author: Raul Sevilla
#
# $evm.object parameters
#  - $evm.object["serverurl"]
#  - $evm.object["username"]
#  - $evm.object.decrypt("password")
#  - $evm.object["timeout"]
#  - $evm.object["protocol"]
#  - $evm.object["port"] 
#  - $evm.object["puppet_check_limit"]
#  - $evm.object["puppet_check_period"]
#  - $evm.object["fqdn"]
#  - $evm.object["puppetclass_id"]
#  - $evm.object["ignore_puppet_warnings"]
#
######################################################

require 'rest-client'
require 'base64'
require 'json'

# Fixed variables

$protocol = $evm.object["protocol"]
$serverurl = $evm.object["serverurl"]
$username = $evm.object["username"]
$password = $evm.object.decrypt("password")
$timeout = $evm.object["timeout"]
$check_limit = $evm.object["puppet_check_limit"]
$check_period = $evm.object["puppet_check_period"]
$port = $evm.object["port"]
$fqdn = $evm.object["fqdn"]
$puppetclass_id = $evm.object["puppetclass_id"]

$headers = {
  "Accept" => "application/json",
  "Content-type" => "application/json"
}

# Helper error method
def error_handler(msg)
  $evm.root["ae_result"] = "error"
  log("error", "ERROR: #{msg}")
  exit MIQ_ABORT
end


def log(loglevel, logmsg)
  # Write a log message.
  # When running inside CFME, use their logging mechanism.
  # Otherwise, write it to stdout.
  if defined? $evm
    $evm.log(loglevel, "#{@method} #{logmsg}")
  else
    puts "#{logmsg}"
  end
end

# Get host report status
def get_host_status
  uri = "#{$protocol}://#{$serverurl}:#{$port}/api/v2/hosts/#{fqdn}"
  begin
    response = RestClient::Request.execute(
			user: $username, 
			password:  $password, 
			method: "get", 
			url: uri, 
			headers: $headers, 
			timeout: $timeout, 
			verify_ssl: false 
	)
    json_data = JSON.parse(response)
    log("info", uri)
    log("info", "Response received #{json_data}")
    puppet_status = json_data["puppet_status"]
    updated_at = json_data["updated_at"]
    host_id = json_data["id"]
    return host_id, puppet_status,updated_at
  rescue Exception => err
    error_handler(err)
  end
end

# Add puppet class to the given host
def add_puppet_class(host_id)
  log("info", "Adding puppet class #{$puppetclass_id} to host #{host_id} (#{$fqdn})")
  uri = "#{$protocol}://#{$serverurl}:#{$port}/api/v2/hosts/#{host_id}/puppetclass_ids"
  log("info", uri)
  body = {
    "puppetclass_id" => $puppetclass_id
  }
  log("info", body)
  begin
    response = RestClient::Request.execute(
			user: $username,
			password: $password,
			method: "post",
	  	    url: uri,
		    headers: $headers,
			timeout: $timeout,
			payload: body.to_json, 
			verify_ssl: false 
	)
  rescue Exception => err
    error_handler(err)
  end
end


host_id, puppet_status, updated_at = get_host_status
add_puppet_class(host_id)
updated = updated_at
elapsed_time = 0
until updated_at != updated
  log("info", "Puppet task not finished yet, checking it in #{$check_period} seconds")
  sleep($check_period)
  elapsed_time = $check_period + elapsed_time
  host_id, puppet_status, updated_at = get_host_status
  if elapsed_time > $check_limit
    error_handler("Check timeout limit reached")
  end
end

if puppet_status == 1
  if not $evm.object["ignore_puppet_warnings"]
    error_handler("Some were found while applying puppet class")
  end
  log("warn", "Some warnings found while applying puppet class")
elsif puppet_status != 0
  error_handler("Error applying puppet provision")
end

log("info", "Puppet provisioning completed")

