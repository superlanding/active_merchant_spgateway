# ActiveMerchantSpgateway

This gem integrate Rails with [spgateway(智付通)](https://www.spgateway.com/).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'active_merchant_spgateway', github: 'afunction/active_merchant_spgateway'
```

And then execute:

```
$ bundle
```

## Setup

- Create file `config/initializers/spgateway.rb`
``` sh
rails g spgateway:install
```

- Go to spgateway and get your credential information. Then fill in `config/initializers/spgateway.rb`
```rb
OffsitePayments::Integrations::Spgateway.setup do |spgateway|
  # You have to apply credential below by yourself.
  spgateway.merchant_id = '123456'
  spgateway.hash_key    = 'xxx'
  spgateway.hash_iv     = 'yyy'
end
```

- Environment configuration:
```rb
# config/environments/development.rb
config.after_initialize do
  ActiveMerchant::Billing::Base.mode = :development
end
```
```rb
# config/environments/production.rb
config.after_initialize do
  ActiveMerchant::Billing::Base.mode = :production
end
```

## Example

- Standard

```
<% payment_service_for  @order,
                        @order.user.email,
                        service: :spgateway,
                        html: { :id => 'spgateway-form', :method => :post } do |service| %>
  <% service.time_stamp @order.created_at %>
  <% service.merchant_order_no @order.id %>
  <% service.amt @order.total_amount.to_i %>
  <% service.item_desc @order.description %>
  <% service.email @order.user.email %>
  <% service.login_type 0 %>
  <% service.encrypted_data %>
  <%= submit_tag '付款' %>
<% end %>
```

- Credit card agreement

```
<% payment_service_for  @order,
                        @order.user.email,
                        service: :spgateway,
                        html: { :id => 'spgateway-form', :method => :post } do |service| %>
  <% service.time_stamp @order.created_at %>
  <% service.merchant_order_no @order.id %>
  <% service.amt @order.total_amount.to_i %>
  <% service.item_desc @order.description %>
  <% service.email @order.user.email %>
  <% service.login_type 0 %>
  <% service.creditagreement 1 %>
  <% service.token_term billing.merchant_id %>
  <% service.encrypted_data %>
  <%= submit_tag '付款' %>
<% end %>
```

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
