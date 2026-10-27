# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Release dates are the dates the version was published on [rubygems.org](https://rubygems.org/gems/active_merchant_spgateway).

## [Unreleased]

> `lib/active_merchant_spgateway/version.rb` on `master` is already `0.1.0`, but that version is **not on rubygems.org yet**
> (the "Publish gem" run for it failed with "No trusted publisher configured for this workflow"), so it is listed here.
> Once 0.1.0 is published, rename this section to `## [0.1.0] - YYYY-MM-DD` and use the date shown on rubygems.org.

### Added

- Support for Rails 7.0, 7.1, 7.2, 8.0 and 8.1 on Ruby 3.0 – 3.4. `actionview` and `activesupport` (`>= 7.0`, `< 8.2`) are now runtime dependencies.
- Unit tests (Minitest) for the form helper, the notification and the install generator; they never touch the network.
- GitHub Actions: a Ruby × Rails test matrix (`test.yml`) and automatic publishing to RubyGems through Trusted Publishing (`publish.yml`).
- `CHANGELOG.md`, a full `README.md`, and a documentation rule in `CLAUDE.md`.

### Changed

- **Breaking:** requires Ruby `>= 3.0` (`required_ruby_version`); Rails older than 7.0 is no longer supported.
- Development dependencies (`bundler`, `rake`, `minitest`) were modernised; the old `rails < 5` development dependency was removed in favour of per-version `gemfiles/`.
- `README.md` installation instructions now use RubyGems instead of the old `github:` source.

## [0.0.4] - 2023-03-15

### Changed

- Point the payment gateway URLs to NewebPay's domain: `https://core.newebpay.com/MPG/mpg_gateway` (production) and `https://ccore.newebpay.com/MPG/mpg_gateway` (development / test), replacing `*.spgateway.com`.

## [0.0.3] - 2018-11-16

Version `0.0.2` was never published to RubyGems, so its changes ship in this release.

### Added

- Credit card agreement (約定信用卡授權) support: the `CREDITAGREEMENT` and `TokenLife` form fields, the `TokenValue` / `TokenLife` notification params, and `Notification#credit_card_agreement_first_trade?` and `Notification#credit_card_agreement_token_trade?`. (from 0.0.2)

### Changed

- Require the `money` gem explicitly and tidy the gemspec metadata.

## [0.0.1] - 2018-11-16

### Added

- Initial release: ActiveMerchant / OffsitePayments integration for the Spgateway (智付通) MPG payment form, the `payment_service_for` helper, notification verification and a Rails install generator (`rails g spgateway:install`).

[Unreleased]: https://github.com/superlanding/active_merchant_spgateway/commits/master
[0.0.4]: https://rubygems.org/gems/active_merchant_spgateway/versions/0.0.4
[0.0.3]: https://rubygems.org/gems/active_merchant_spgateway/versions/0.0.3
[0.0.1]: https://rubygems.org/gems/active_merchant_spgateway/versions/0.0.1
