# CLAUDE.md

## 發版規則（Ruby gem）

- 這個 gem（`active_merchant_spgateway`，gemspec：`active_merchant_spgateway.gemspec`）在 master 收到「新版本號」時，由 GitHub Actions（`.github/workflows/publish.yml`）自動發佈到 rubygems.org（Trusted Publishing，不使用 API key）。
- **每一個 PR 都必須跳版號**（改 `lib/active_merchant_spgateway/version.rb`），除非這個 PR 只改文件、CI 或 CLAUDE.md 且明確不需要發版。沒跳版號的 PR 合進 master 後不會發佈。
- 跳版規則（Semantic Versioning）：修 bug 跳 patch（x.y.Z）；新增相容功能跳 minor（x.Y.0）；不相容變更跳 major（X.0.0）。
- 版號只改在 PR 裡。AI 帳號只能開 branch 與 PR，不得合併到 master；只有真人帳號可以合併。合併就等於批准發佈。
- 不得為了讓測試通過而改變程式原本的行為。
