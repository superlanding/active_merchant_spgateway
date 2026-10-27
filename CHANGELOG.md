# 更新紀錄（Changelog）

本檔記錄此專案所有值得注意的變更。

格式參考 [Keep a Changelog](https://keepachangelog.com/zh-TW/1.1.0/)，版本號遵循 [Semantic Versioning](https://semver.org/lang/zh-TW/)。

日期為該版本發佈到 [rubygems.org](https://rubygems.org/gems/active_merchant_spgateway) 的日期。

## [Unreleased]

> `master` 上的 `lib/active_merchant_spgateway/version.rb` 已經是 `0.1.0`，但這個版本**還沒有發佈到 rubygems.org**
> （該版本的 "Publish gem" 執行失敗，錯誤為 "No trusted publisher configured for this workflow"），所以先列在這裡。
> 等 0.1.0 發佈後，請把這個區塊改名為 `## [0.1.0] - YYYY-MM-DD`，並使用 rubygems.org 上顯示的日期。

### Added

- 支援 Rails 7.0、7.1、7.2、8.0 與 8.1（Ruby 3.0 – 3.4）。`actionview` 與 `activesupport`（`>= 7.0`, `< 8.2`）現在是 runtime 相依套件。
- 針對 form helper、notification 與 install generator 補上單元測試（Minitest）；測試不會連網。
- GitHub Actions：Ruby × Rails 測試矩陣（`test.yml`），以及透過 Trusted Publishing 自動發佈到 RubyGems（`publish.yml`）。
- `CHANGELOG.md`、完整的 `README.md`，以及 `CLAUDE.md` 裡的文件規則。
- `CLAUDE.md` 規定 `README.md` 與 `CHANGELOG.md` 一律用繁體中文撰寫。

### Changed

- **不相容變更：** 需要 Ruby `>= 3.0`（`required_ruby_version`）；不再支援 7.0 以前的 Rails。
- 更新開發相依套件（`bundler`、`rake`、`minitest`）；移除舊的 `rails < 5` 開發相依，改用各版本專屬的 `gemfiles/`。
- `README.md` 的安裝說明改用 RubyGems，不再使用舊的 `github:` 來源。
- `README.md`、`CHANGELOG.md` 改以繁體中文（zh-TW）撰寫。

## [0.0.4] - 2023-03-15

### Changed

- 付款閘道 URL 改指向藍新（NewebPay）的網域：`https://core.newebpay.com/MPG/mpg_gateway`（正式環境）與 `https://ccore.newebpay.com/MPG/mpg_gateway`（開發 / 測試環境），取代原本的 `*.spgateway.com`。

## [0.0.3] - 2018-11-16

版本 `0.0.2` 從未發佈到 RubyGems，所以它的變更一併在這個版本釋出。

### Added

- 約定信用卡授權支援：表單欄位 `CREDITAGREEMENT` 與 `TokenLife`、通知參數 `TokenValue` / `TokenLife`，以及 `Notification#credit_card_agreement_first_trade?` 與 `Notification#credit_card_agreement_token_trade?`。（來自 0.0.2）

### Changed

- 明確 require `money` gem，並整理 gemspec 的 metadata。

## [0.0.1] - 2018-11-16

### Added

- 首次發佈：Spgateway（智付通）MPG 付款表單的 ActiveMerchant / OffsitePayments 整合、`payment_service_for` helper、通知驗證，以及 Rails install generator（`rails g spgateway:install`）。

[Unreleased]: https://github.com/superlanding/active_merchant_spgateway/commits/master
[0.0.4]: https://rubygems.org/gems/active_merchant_spgateway/versions/0.0.4
[0.0.3]: https://rubygems.org/gems/active_merchant_spgateway/versions/0.0.3
[0.0.1]: https://rubygems.org/gems/active_merchant_spgateway/versions/0.0.1
