module GithubConsumer
  class Client

    # The class constructor
    def initialize
      @hydra = Typhoeus::Hydra.new(max_concurrency: 14)
    end

    # Builds a request, puts it inside a queue and returns it
    def register_request(url, &block)
      request = Typhoeus::Request.new url
      request.on_complete do |response|
	#issues_set.warn_issue_processed
        if response.success?
          json = JSON.parse(response.body)
          if !json.is_a?(Hash) || json['message'].nil?
            puts "[OK-#{response.cached?}] #{url}"
            block.call(json)
          else
            puts "[ERR] #{url} #{json.inspect}"
          end
        else
          puts "[FAIL-#{response.cached?}] #{url}"
        end
      end
      @hydra.queue request
      request
    end

    # Executes the queue of requests
    def run_requests
      @hydra.run
    end

    # Gives size of queue (needed for HTML bar)
    def requests_amount
      @hydra.queue.size
    end
  end
end
