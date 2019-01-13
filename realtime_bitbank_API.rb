require 'pubnub'
require 'logger'

class RealtimeBitbankAPI
    Subscribe_Key = 'sub-c-e12e9174-dd60-11e6-806b-02ee2ddab7fe'

    def initialize(type, coin1, coin2, log, queue)
        @channel = "#{type}_#{coin1}_#{coin2}"
        @log = log
        @queue = queue
        pubnub_log = Logger.new('./log/pubnub.log')
        pubnub_log.level = Logger::INFO
        pubnub_log.level = Logger::WARN
        @pubnub = Pubnub.new(
            subscribe_key: Subscribe_Key,
            ssl: true,
            logger: pubnub_log
        )
        @log.info("[PubNub] Start")
        @before = Time.now

        callback = Pubnub::SubscribeCallback.new(
            message: ->(envelope){
                #write process here
                now = Time.now
                if (now - @before) >= 3 #interval to get data
                    @before = now
                    if envelope.result[:code] == 200
                        @queue.push(envelope.result[:data][:message]["data"])
                    else
                        @queue.push(201)
                        @log.warn("[PubNub] Error in message: #{envelope.result[:code]}")
                    end
                end
            },
            status: lambda { |envelope|
                if envelope.error?
                    @queue.push(202)
                    @log.warn("[PubNub] Error in status: #{envelope.status[:category]}")
                    puts "ERROR! #{envelope.status[:category]}"
                else
                    if envelope.status[:last_timetoken] == 0
                        @log.info("[PubNub] Connected")
                        puts "PubNub Connected"
                    end
                end
            }
        )

        @pubnub.add_listener(
            callback: callback
        )
        @pubnub.subscribe(
            channels: @channel
        )
    end

    public
    def unsubscribe
        @pubnub.unsubscribe(
            channel: @channel
        ) do |envelope|
            @log.info("[PubNub] Disconnected")
            puts "PubNub Disconnected"
        end
    end
end
