#  RXARF  [![Build Status](https://travis-ci.org/gunnarhelgason/rxarf.png?branch=master)](https://travis-ci.org/gunnarhelgason/rxarf) [![Code Climate](https://codeclimate.com/github/gunnarhelgason/rxarf.png)](https://codeclimate.com/github/gunnarhelgason/rxarf)

Ruby library for creating, reading and validating X-ARF reports.

## Installation

Add this line to your application's Gemfile:

    gem 'rxarf'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rxarf

## Usage

### Creating a report

```ruby
mail = Mail.new do
  from    'mikel@test.lindsaar.net'
  to      'you@test.lindsaar.net'
  subject 'This is a test email'
  body    File.read('body.txt')
end

mail.to_s #=> "From: mikel@test.lindsaar.net\r\nTo: you@...
```

### Reading and validating a report

``` ruby
mail = Mail.new do
  from    'mikel@test.lindsaar.net'
  to      'you@test.lindsaar.net'
  subject 'This is a test email'
  body    File.read('body.txt')
end

mail.to_s #=> "From: mikel@test.lindsaar.net\r\nTo: you@...
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
