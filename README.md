# bitbank.cc API by Ruby

This makes it easy to call the API of bitbank in Ruby.  

## Installation

Clone this repository.  

## Usage

These use gems "active_support" and "pubnub".  
Install before use these.  

```sh
bundle init
```

```txt:Gemfile
gem "activesupport"
gem "pubnub"
```

```sh
bundle install --path=vendor/bundle
```

### bitbank_api

```ruby:sample1.rb
require './bitbank_api'

bitbank = BitbankAPI.new(
        (your api key), # can be nil
        (your api secret), # can be nil
        "btc",
        "jpy"
    )
```

The following informations can be called.  
For details, please see [official documents](https://docs.bitbank.cc/).

#### Public API (Available without API key and secret)
- ticker
- depth
- transactions
- candlestick

```ruby:sample2.rb
bitbank.ticker

bitbank.depth

#                    date
bitbank.transactions("20190126") # Argument can be nil

#                   term   , date
bitbank.candlestick("15min", "20190126")
```

#### Private API (Need API key and secret)
- read assets
- read order
- read status

```ruby:sample3.rb
# sample

bitbank.read_assets

bitbank.read_order

bitbank.read_status
```

- create order
- cancel order

```ruby:sample4.rb
#                     price, amount, side, type
bitbank.create_order(400000, 1.0, "buy", "limit")

#                    order id
bitbank.create_order(583273428)
```

If errors occur in https connection, each methods return `301`.  
In case of bitbank API error, methods return response code.  
If there is no error, those return data in `json` format.  

### realtime_bitbank_api

```ruby:sample5.rb
require 'realtime_bitbank_api'

log = Logger.new("./log20180126.log")
queue = Queue.new

pubnub = RealtimeBitbankAPI.new("candlestick", "btc", "jpy", log, queue)

#####
# trading ...
#####

pubnub.unsubscribe
```

Following are prepared in pubnub.  
- ticker
- depth
- transactions
- candlestick

For details, please see [official documents](https://docs.bitbank.cc/).  

Data reception from pubnub channel is started when pubnub instance is created.  
To Receive Data, use 'queue.pop'.  
In default, data is popeed into the queue once every three seconds.  

## Future　(if I have time)
- Add comments to code for easy understanding.
- Add logging function in bitbank_api
