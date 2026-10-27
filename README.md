# ActiveMerchantSpgateway

為 Rails 提供 **Spgateway（智付通，現為藍新金流 NewebPay）** `MPG`（多功能收款）的 [ActiveMerchant](https://github.com/activemerchant/active_merchant) / [OffsitePayments](https://github.com/activemerchant/offsite_payments) 整合。有了它，Rails 應用程式可以：

- 產生含 hidden 欄位的表單，把消費者導向 Spgateway / NewebPay 的付款頁（包含 `CheckValue` 簽章），以及
- 解析並驗證 Spgateway 回傳的背景通知 / 返回通知（`CheckCode`）。

這個 gem 發佈在 [RubyGems](https://rubygems.org/gems/active_merchant_spgateway)。各版本的變更請見 [CHANGELOG.md](CHANGELOG.md)。

## 環境需求

| | 支援版本 |
| --- | --- |
| Ruby | 3.0、3.1、3.2、3.3、3.4 |
| Rails（`actionview` / `activesupport`） | 7.0、7.1、7.2、8.0、8.1 |

Rails 7.2 需要 Ruby >= 3.1，Rails 8.0 / 8.1 需要 Ruby >= 3.2。以上正是 CI 矩陣（`.github/workflows/test.yml`）所跑的組合。其他 runtime 相依套件：`activemerchant ~> 1.50`、`offsite_payments ~> 2`、`money`。

## 安裝

在應用程式的 `Gemfile` 加入這一行：

```ruby
gem 'active_merchant_spgateway', '>= 0.1.0'
```

然後執行：

```sh
bundle install
```

> 支援 Rails 7+ / Ruby 3+ 的版本是 **0.1.0**。如果 RubyGems 上還看不到 0.1.0（請查看 [CHANGELOG](CHANGELOG.md)），請改用 Git 來源：
> `gem 'active_merchant_spgateway', github: 'superlanding/active_merchant_spgateway'`。

## 設定

1. 產生 initializer：

   ```sh
   rails g spgateway:install
   ```

   這會建立 `config/initializers/spgateway.rb`。

2. 填入從 Spgateway / NewebPay 商店後台取得的憑證：

   ```ruby
   # config/initializers/spgateway.rb
   OffsitePayments::Integrations::Spgateway.setup do |spgateway|
     spgateway.merchant_id = '123456'
     spgateway.hash_key    = 'your 32-character HashKey'
     spgateway.hash_iv     = 'your 16-character HashIV'

     # 選填：加到每張表單的預設值（全部都是選填）：
     # spgateway.notify_url   = 'https://example.com/spgateway/notify'
     # spgateway.lang_type    = 'zh-tw'   # LangType
     # spgateway.login_type   = 0         # LoginType
     # spgateway.trade_limit  = 600       # TradeLimit（秒）
     # spgateway.expire_date  = 7         # ExpireDate（天）
     # spgateway.email_modify = 1         # EmailModify
   end
   ```

   `hash_key` / `hash_iv` 不要放進版本控制（請用 Rails credentials 或環境變數）。

3. 選擇環境。付款閘道的 URL 取決於 `ActiveMerchant::Billing::Base.mode`：

   | mode | URL |
   | --- | --- |
   | `:production` | `https://core.newebpay.com/MPG/mpg_gateway` |
   | `:development` / `:test` | `https://ccore.newebpay.com/MPG/mpg_gateway`（測試環境） |

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

## 使用方式

### 1. 把消費者導向付款頁

`payment_service_for` 可以在 view 裡使用。請一律最後才呼叫 `service.encrypted_data`；它會用 `Amt`、`MerchantID`、`MerchantOrderNo`、`TimeStamp` 與 `Version` 計算 `CheckValue`。

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

這會輸出一個指向上述閘道 URL 的 `<form method="post">`，內含 hidden 欄位 `MerchantID`、`Version`（`1.2`）、`RespondType`、`TimeStamp`、`MerchantOrderNo`、`Amt`、`ItemDesc`、`Email`、`LoginType`、`CheckValue` 等。

Spgateway 的每個欄位都有對應的 snake_case setter：`merchant_id`、`lang_type`、`merchant_order_no`、`amt`、`item_desc`、`trade_limit`、`expire_date`、`return_url`、`notify_url`、`customer_url`、`client_back_url`、`email`、`email_modify`、`login_type`、`order_comment`、`credit`、`credit_red`、`inst_flag`、`unionpay`、`webatm`、`vacc`、`cvs`、`barcode`、`custom`、`token_term`、`creditagreement`、`token_life`。`account` 與 `amount` 分別是 `merchant_id` 與 `amt` 的別名。

如果某張表單要用不同的 HashKey / HashIV（例如有多個商店），請在 `service.encrypted_data` 之前呼叫 `service.hash_key '...'` 與 `service.hash_iv '...'`。

### 2. 約定信用卡授權

加上 `creditagreement` 與 `token_term`（你自己定義的唯一會員識別碼）：

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

### 3. 處理通知

把 `notify_url`（及 / 或 `return_url`）指向某個 controller action，該 action 要略過 CSRF 驗證，並且在信任資料之前先驗證簽章：

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

notification 上可用的輔助方法：

- `checksum_ok?` / `acknowledge`：驗證 `CheckCode`（以你的 `HashIV` / `HashKey` 對 `Amt`、`MerchantID`、`MerchantOrderNo`、`TradeNo` 做 SHA256）。Spgateway 沒有遠端驗證機制，所以這是唯一的真偽檢查，**請務必呼叫**。
- `success?`：`Status == 'SUCCESS'`；`complete?`：`Status` 為 `SUCCESS` 或 `CUSTOM`。
- 原始欄位的 snake_case reader：`status`、`message`、`merchant_id`、`amt`、`trade_no`、`merchant_order_no`、`payment_type`、`pay_time`、`check_code`、`card6_no`、`card4_no`、`pay_bank_code`、`code_no`、`bank_code`、`barcode_1` 等（見 `notification.rb` 的 `PARAMS_FIELDS`）。注意父類別的 `gross` 方法**沒有**實作，請改用 `amt`。
- `credit_card_agreement_first_trade?`：約定信用卡授權的第一筆交易（`TokenUseStatus == '1'`）；`credit_card_agreement_token_trade?`：之後以 token 進行的交易。`token_value` 與 `token_life` reader 帶有 token 資料。
- 若要用各商店自己的金鑰驗證，請在 `checksum_ok?` 之前設定 `notification.hash_key = '...'` 與 `notification.hash_iv = '...'`。

## 開發

```sh
git clone https://github.com/superlanding/active_merchant_spgateway.git
cd active_merchant_spgateway
BUNDLE_GEMFILE=gemfiles/rails_8.1.gemfile bundle install
BUNDLE_GEMFILE=gemfiles/rails_8.1.gemfile bundle exec rake t   # `rake test:units` 的別名
```

請在 `gemfiles/` 裡挑一個符合你 Ruby 版本的 gemfile（`rails_7.0` … `rails_8.1`）。測試是一般的 Minitest，放在 `test/unit/`，並且會封鎖所有網路存取（任何 `Net::HTTP` 連線都會 raise）。設定 `COVERAGE=1` 可執行 SimpleCov。

CI（`.github/workflows/test.yml`）會在每個 PR 以及 push 到 `master` 時跑完整的 Ruby × Rails 矩陣。

## 發版

發版是自動的（RubyGems [Trusted Publishing](https://guides.rubygems.org/trusted-publishing/)，不存放 API key）：

1. 在你的 PR 裡修改 `lib/active_merchant_spgateway/version.rb` 的 `ActiveMerchantSpgateway::VERSION`（SemVer），並把 `CHANGELOG.md` 裡 `## [Unreleased]` 底下的條目移到新的 `## [x.y.z] - YYYY-MM-DD` 區塊。
2. 把 PR 合併進 `master`。
3. `.github/workflows/publish.yml` 發現這個版本還不在 rubygems.org 上，就會打包 gem 並執行 `rake release`，發佈 gem 並建立 `vx.y.z` git tag。如果該版本已經存在，workflow 什麼都不會做。

沒有跳版號的 PR（文件、CI、重構）永遠不會被發佈。

## 貢獻

歡迎到 GitHub 回報問題與提交 pull request：https://github.com/superlanding/active_merchant_spgateway。每個 pull request 也都必須同步更新這份 README（當行為、用法或環境需求有變時），並在 `CHANGELOG.md` 新增一筆條目；請見 `CLAUDE.md`。

## 授權

本 gem 以 [MIT License](LICENSE.txt) 條款開源。
