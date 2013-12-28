#  RXARF  [![Build Status](https://travis-ci.org/gunnarhelgason/rxarf.png?branch=master)](https://travis-ci.org/gunnarhelgason/rxarf) [![Code Climate](https://codeclimate.com/github/gunnarhelgason/rxarf.png)](https://codeclimate.com/github/gunnarhelgason/rxarf)

Ruby library for creating, reading and validating [X-ARF](http://www.x-arf.org/) reports. Work in progress.

## Installation

Add this line to your application's Gemfile:

    gem 'rxarf'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rxarf

## Usage

### Initializing

```ruby
xarf = XARF.new(
  {
    :header_defaults => {
      :from => 'from@defaultsender.net'
    },
    :report_defaults => {
      :user_agent => 'our user agent'
    }
  }
)
```

### Creating a report

```ruby
msg = xarf.create(schema: "http://www.x-arf.org/schema/fraud_0.1.4.json") do |msg|
  msg.header.to = 'abuse@isp.net'
  ...
  msg.report.report_type = 'phishing'
  ...
  msg.human_readable = "Human readable text describing incident"
  msg.attachment = ...
end
```

### Reading and validating a report

``` ruby
xarf.load(string_containing_message)
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
