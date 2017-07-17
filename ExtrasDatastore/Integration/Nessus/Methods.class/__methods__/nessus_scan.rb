#
# Description: Launch and evaluates a nessus scan
#
# Author: Raul Sevilla
#
# Input parameters:
# - $evm.object["serverurl"] Nessus server url
# - $evm.object["access_key"] Nessus access key
# - $evm.object["secret_key"] Nessus secret key
# - $evm.object["timeout"] Nessus API request timeout
# - $evm.object["protocol"] Nessus server protocol
# - $evm.object["port"] Nessus server port
# - $evm.object["check_limit"] Check limit in Nessus scan
# - $evm.object["check_period"] Check period in Nessus scan 
# - $evm.object["ciritcal"] Vulnerability level treshold
# - $evm.object["scan_list"] Scan list to perform in the server
#
########################################################

require 'rest-client'
require 'json'

begin
  @serverurl = $evm.object["serverurl"]
  @access_key = $evm.object["access_key"]
  @secret_key = $evm.object.decrypt("secret_key") 
  @timeout = $evm.object["timeout"]
  @protocol = $evm.object["protocol"]
  @port = $evm.object["port"]
  @check_limit = $evm.object["check_limit"]
  @check_period = $evm.object["check_period"]
  @critical = $evm.object["critical_level"] 
  @scan_list = $evm.object["scan_list"] 

  @threat_list = []

  target = $evm.root["vm"].ipaddr

  @headers = {}

  def set_headers
    log("info", "Setting headers for access_key #{@access_key}")
    @headers = {
      "X-ApiKeys" => "accessKey=#{@access_key}; secretKey=#{@secret_key}",
      "content-type" => "application/json"
  }
  end

  def log(loglevel, logmsg)
    # Write a log message.
    # When running inside CFME, use their logging mechanism.
    # Otherwise, write it to stdout.
    if defined? $evm
      $evm.log(loglevel, "#{logmsg}")
    else
      puts "#{logmsg}"
    end
  end

  def print_banner(msg)
    log("info", "#" * (msg.length + 4))
    log("info", "# #{msg} #")
    log("info", "#" * (msg.length + 4))
  end

  def check_availability
    log("info", "Checking availability of nessus server")
    set_headers
    res = RestClient::Request::execute(method: :get, url: "#{@protocol}://#{@serverurl}:#{@port}/", :verify_ssl => $evm.object["verify_ssl"])
    log("info", "Nessus #{@protocol}://#{@serverurl}:#{@port}/ available")
    return
  end

  def rest_request(uri, body=nil)
    log("info", uri)
    if body
      log("info", "body #{body}")
      res = RestClient::Request::execute(method: :post, url: uri, headers: @headers, timeout: @timeout, payload: body.to_json, :verify_ssl => $evm.object["verify_ssl"])
    else
      res = RestClient::Request::execute(method: :get, url: uri, headers: @headers, timeout: @timeout, :verify_ssl => $evm.object["verify_ssl"])
    end
    json_data = JSON.parse(res.body)
    log("debug", "Response received: #{json_data}")
    json_data
  end


  def get_scan_id(scanname)
    elapsed_time = 0
    found = false
    log("info", "Getting scan ID of #{scanname}")
    uri = "#{@protocol}://#{@serverurl}:#{@port}/scans"
    while true
      scan_list = rest_request(uri)
      # Iterate over all scans
      scan_list["scans"].each do |scan|
        # Get scan ID
        if scan["name"] == scanname
          found = true
          log("info", "#{scanname} ID: #{scan['id']}")
          # Check if scan is running, it may be running due to a previous provisioning operation
          if scan["status"] == "running"
            log("info", "Another [#{scanname}] scan is running, waiting for it to finish before launching a new one")
            sleep(@check_period)
            elapsed_time = @check_period + elapsed_time
            # Avoid infinite loops of checking with a check timeout
            if elapsed_time > @check_limit
              raise("Check timeout limit reached")
            end
            break
          else
            scan["id"]
          end
        end
      end
      unless found
        raise("Scan #{scanname} not found in Nessus")
      end
    end
  end


  def launch_scan(scan_id, target)
    log("info", "Launching scan #{scan_id} over #{target}")
    uri = "#{@protocol}://#{@serverurl}:#{@port}/scans/#{scan_id}/launch"
    body = {"alt_targets" => [target]}
    rest_request(uri, body)
  end


  def check_scan(scan_id)
    log("info", "Checking if scan has finished")
    uri = "#{@protocol}://#{@serverurl}:#{@port}/scans/#{scan_id}"
    resp = rest_request(uri)
    elapsed_time = 0
    while resp["info"]["status"] == "running"
      log("info", "Scan #{scan_id} in progress")
      elapsed_time = @check_period + elapsed_time
      sleep(@check_period)
      resp = rest_request(uri)
      if elapsed_time > @check_limit
        raise("Check timeout limit reached")
      end
    end
    resp
  end


  def eval_result(scan_result)
    for threat in scan_result["vulnerabilities"]
      if threat["severity"] == @critical
        @threat_list << vulnerability
      end
    end
  end

  print_banner("nessus_scan method started")
  check_availability
  @scan_list.each do |scan|
    scan_id = get_scan_id(scan["scanname"])
    launch_scan(scan_id, target)
    scan_result = check_scan(scan_id)
    eval_result(scan_result)
    if @threat_list.any? 
      raise("Critical vulnerabilities found in #{scan['scanname']}:\n#{@threat_list}")
    else
      log("info", "No critical vulnerabilities found in #{scan['scanname']}")
      @threat_list = []
    end
  end
  
rescue Exception => err
  log(:error, "[#{err}]\n#{err.backtrace.join("\n")}")
  exit MIQ_STOP
end
