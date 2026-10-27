# CLAUDE.md

## 發版規則（Ruby gem）

- 這個 gem（`active_merchant_spgateway`，gemspec：`active_merchant_spgateway.gemspec`）在 master 收到「新版本號」時，由 GitHub Actions（`.github/workflows/publish.yml`）自動發佈到 rubygems.org（Trusted Publishing，不使用 API key）。
- **每一個 PR 都必須跳版號**（改 `lib/active_merchant_spgateway/version.rb`），除非這個 PR 只改文件、CI 或 CLAUDE.md 且明確不需要發版。沒跳版號的 PR 合進 master 後不會發佈。
- 跳版規則（Semantic Versioning）：修 bug 跳 patch（x.y.Z）；新增相容功能跳 minor（x.Y.0）；不相容變更跳 major（X.0.0）。
- 版號只改在 PR 裡。AI 帳號只能開 branch 與 PR，不得合併到 master；只有真人帳號可以合併。合併就等於批准發佈。
- 不得為了讓測試通過而改變程式原本的行為。

## 文件與更新紀錄（README / CHANGELOG）

- **每一個 PR 都必須同步更新文件**：
  - 只要行為、用法、設定、相依套件或支援的 Ruby / Rails 版本有變，就要更新 `README.md`。
  - 一律要在 `CHANGELOG.md` 新增一筆條目（[Keep a Changelog](https://keepachangelog.com/zh-TW/1.1.0/) 格式，分類用 Added / Changed / Deprecated / Removed / Fixed / Security）。
- **語言規則**：`README.md` 與 `CHANGELOG.md` 一律用繁體中文（zh-TW，台灣用語）撰寫；程式碼、識別字（class / 方法 / 變數名稱）、指令、檔名與路徑維持英文，不要翻譯。
- `CHANGELOG.md` 的寫法：
  - 沒有跳版號的 PR：寫在最上方的 `## [Unreleased]` 底下。
  - 有跳版號的 PR：把條目寫在新的版本章節 `## [x.y.z] - YYYY-MM-DD`（日期為合併日），並同步更新檔尾的版本比較連結。
  - 版本號必須與 rubygems.org 上實際發佈的版本一致，不得寫還沒發佈的版本。
- 只改文件、CI 或 CLAUDE.md 的 PR 不需要跳版號，但仍要在 `CHANGELOG.md` 的 `Unreleased` 補一筆。
