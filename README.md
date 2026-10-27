# ActiveMerchantSpgateway

[ActiveMerchant](https://github.com/activemerchant/active_merchant) / [OffsitePayments](https://github.com/activemerchant/offsite_payments) integration for **Spgateway (智付通, now NewebPay 藍新金流)** `MPG` (multi-payment gateway) for Rails. It lets a Rails app:

- render the hidden-field form that sends a customer to the Spgateway / NewebPay payment page (including the `CheckValue` signature), and
- parse and verify the server-to-server / return notification (`CheckCode`) Spgateway posts back.

The gem is published on [RubyGems](https://rubygems.org/gems/active_merchant_spgateway). See [CHANGELOG.md](CHANGELOG.md) for what changed in each version.

## Requirements

| | Supported |
| --- | --- |
| Ruby | 3.0, 3.1, 3.2, 3.3, 3.4 |
| Rails (`actionview` / `activesupport`) | 7.0, 7.1, 7.2, 8.0, 8.1 |

Rails 7.2 needs Ruby >= 3.1, and Rails 8.0 / 8.1 need Ruby >= 3.2. These are exactly the combinations the CI matrix (`.github/workflows/test.yml`) runs. Other runtime dependencies: `activemerchant ~> 1.50`, `offsite_payments ~> 2`, `money`.

## Installation

Add this line to your application's `Gemfile`:

```ruby
gem 'active_merchant_spgateway', '>= 0.1.0'
```

Then run:

```sh
bundle install
```

> Support for Rails 7+ / Ruby 3+ is released as **0.1.0**. If 0.1.0 is not yet visible on RubyGems (check the [CHANGELOG](CHANGELOG.md)), use the Git source instead:
> `gem 'active_merchant_spgateway', github: 'superlanding/active_merchant_spgateway'`.

## Configuration

1. Generate the initializer:

   ```sh
   rails g spgateway:install
   ```

   This creates `config/initializers/spgateway.rb`.

2. Fill in the credentials you get from the Spgateway / NewebPay merchant back office:

   ```ruby
   # config/initializers/spgateway.rb
   OffsitePayments::Integrations::Spgateway.setup do |spgateway|
     spgateway.merchant_id = '123456'
     spgateway.hash_key    = 'your 32-character HashKey'
     spgateway.hash_iv     = 'your 16-character HashIV'

     # Optional defaults added to every form (all are optional):
     # spgateway.notify_url   = 'https://example.com/spgateway/notify'
     # spgateway.lang_type    = 'zh-tw'   # LangType
     # spgateway.login_type   = 0         # LoginType
     # spgateway.trade_limit  = 600       # TradeLimit (seconds)
     # spgateway.expire_date  = 7         # ExpireDate (days)
     # spgateway.email_modify = 1         # EmailModify
   end
   ```

   Keep `hash_key` / `hash_iv` out of version control (Rails credentials or environment variables).

3. Choose the environment. The gateway URL depends on `ActiveMerchant::Billing::Base.mode`:

   | mode | URL |
   | --- | --- |
   | `:production` | `https://core.newebpay.com/MPG/mpg_gateway` |
   | `:development` / `:test` | `https://ccore.newebpay.com/MPG/mpg_gateway` (sandbox) |

   ```ruby
   # config/environments/development.rb
   config.after_initialize do
     ActiveMerchant::Billing::Base.mode = :development
   end
   ```

   ```ruby
   # config/environments/production.rb
   config.after_initialize do
     ActiveMerchant::Billing::Base.mode = :production
   end
   ```

## Usage

### 1. Send the customer to the payment page

`payment_service_for` is available in views. Always call `service.encrypted_data` last; it computes `CheckValue` from `Amt`, `MerchantID`, `MerchantOrderNo`, `TimeStamp` and `Version`.

```erb
<% payment_service_for @order,
                       @order.user.email,
                       service: :spgateway,
                       html: { id: 'spgateway-form', method: :post } do |service| %>
  <% service.time_stamp @order.created_at %>
  <% service.merchant_order_no @order.id %>
  <% service.amt @order.total_amount.to_i %>
  <% service.item_desc @order.description %>
  <% service.email @order.user.email %>
  <% service.login_type 0 %>
  <% service.encrypted_data %>
  <%= submit_tag 'Pay' %>
<% end %>
```

This renders a `<form method="post">` pointing at the gateway URL above with hidden inputs `MerchantID`, `Version` (`1.2`), `RespondType`, `TimeStamp`, `MerchantOrderNo`, `Amt`, `ItemDesc`, `Email`, `LoginType`, `CheckValue`, …

Every Spgateway field has a snake_case setter: `merchant_id`, `lang_type`, `merchant_order_no`, `amt`, `item_desc`, `trade_limit`, `expire_date`, `return_url`, `notify_url`, `customer_url`, `client_back_url`, `email`, `email_modify`, `login_type`, `order_comment`, `credit`, `credit_red`, `inst_flag`, `unionpay`, `webatm`, `vacc`, `cvs`, `barcode`, `custom`, `token_term`, `creditagreement`, `token_life`. `account` and `amount` are aliases of `merchant_id` and `amt`.

To use a different HashKey / HashIV for one form (for example for multiple merchants), call `service.hash_key '...'` and `service.hash_iv '...'` before `service.encrypted_data`.

### 2. Credit card agreement (約定信用卡授權)

Add `creditagreement` and `token_term` (your own unique member identifier):

```erb
<% payment_service_for @order, @order.user.email, service: :spgateway,
                       html: { id: 'spgateway-form', method: :post } do |service| %>
  <% service.time_stamp @order.created_at %>
  <% service.merchant_order_no @order.id %>
  <% service.amt @order.total_amount.to_i %>
  <% service.item_desc @order.description %>
  <% service.email @order.user.email %>
  <% service.login_type 0 %>
  <% service.creditagreement 1 %>
  <% service.token_term @order.user.id.to_s %>
  <% service.encrypted_data %>
  <%= submit_tag 'Pay' %>
<% end %>
```

### 3. Handle the notification

Point `notify_url` (and/or `return_url`) at a controller action, skip CSRF verification for it, and verify the signature before trusting the data:

```ruby
class SpgatewayController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :notify

  def notify
    notification = OffsitePayments::Integrations::Spgateway.notification(request.raw_post)

    if notification.checksum_ok? && notification.complete?
      order = Order.find_by!(id: notification.merchant_order_no)
      # notification.amt, notification.trade_no, notification.payment_type, notification.pay_time ...
      order.mark_as_paid!(trade_no: notification.trade_no)
    end

    head :ok
  end
end
```

Available helpers on the notification:

- `checksum_ok?` / `acknowledge` — verifies `CheckCode` (SHA256 of `Amt`, `MerchantID`, `MerchantOrderNo`, `TradeNo` with your `HashIV` / `HashKey`). Spgateway has no remote verification, so this is the only authenticity check; **always call it**.
- `success?` — `Status == 'SUCCESS'`; `complete?` — `Status` is `SUCCESS` or `CUSTOM`.
- Raw fields as snake_case readers: `status`, `message`, `merchant_id`, `amt`, `trade_no`, `merchant_order_no`, `payment_type`, `pay_time`, `check_code`, `card6_no`, `card4_no`, `pay_bank_code`, `code_no`, `bank_code`, `barcode_1` … (see `PARAMS_FIELDS` in `notification.rb`). Note the base class method `gross` is **not** implemented; use `amt`.
- `credit_card_agreement_first_trade?` — first transaction of a credit card agreement (`TokenUseStatus == '1'`); `credit_card_agreement_token_trade?` — a later token transaction. The `token_value` and `token_life` readers carry the token data.
- To verify with a per-merchant key, set `notification.hash_key = '...'` and `notification.hash_iv = '...'` before `checksum_ok?`.

## Development

```sh
git clone https://github.com/superlanding/active_merchant_spgateway.git
cd active_merchant_spgateway
BUNDLE_GEMFILE=gemfiles/rails_8.1.gemfile bundle install
BUNDLE_GEMFILE=gemfiles/rails_8.1.gemfile bundle exec rake t   # alias of `rake test:units`
```

Pick any gemfile in `gemfiles/` (`rails_7.0` … `rails_8.1`) that matches your Ruby version. The tests are plain Minitest, live in `test/unit/`, and block all network access (any `Net::HTTP` connection raises). Set `COVERAGE=1` to run SimpleCov.

CI (`.github/workflows/test.yml`) runs the whole Ruby × Rails matrix for every PR and push to `master`.

## Releasing

Releases are automatic (RubyGems [Trusted Publishing](https://guides.rubygems.org/trusted-publishing/), no API key stored):

1. In your PR, bump `ActiveMerchantSpgateway::VERSION` in `lib/active_merchant_spgateway/version.rb` (SemVer) and move the `## [Unreleased]` entries in `CHANGELOG.md` under a new `## [x.y.z] - YYYY-MM-DD` section.
2. Merge the PR into `master`.
3. `.github/workflows/publish.yml` sees that the version is not on rubygems.org yet, builds the gem and runs `rake release`, which publishes it and creates the `vx.y.z` git tag. If the version already exists, the workflow does nothing.

PRs that do not bump the version (docs, CI, refactors) are never published.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/superlanding/active_merchant_spgateway. Every pull request must also update this README (when behaviour, usage or requirements change) and add an entry to `CHANGELOG.md`; see `CLAUDE.md`.

## License

The gem is available as open source under the terms of the [MIT License](LICENSE.txt).
