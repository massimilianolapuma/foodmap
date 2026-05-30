## Summary

<!-- What does this PR change and why? Link the issue it closes. -->

Closes #

## Type of change

- [ ] feat — new feature
- [ ] fix — bug fix
- [ ] chore — tooling / docs / maintenance
- [ ] test — tests only
- [ ] refactor — no behaviour change

## Checklist (verified locally before pushing)

- [ ] `xcodegen generate`
- [ ] `swiftformat .`
- [ ] `swiftlint --strict` (0 violations)
- [ ] `xcodebuild -scheme FoodMap -destination 'platform=iOS Simulator,name=iPhone 17' test CODE_SIGNING_ALLOWED=NO` (green)
- [ ] Changes respect Clean Architecture layering (Domain ← Data ← Presentation)
- [ ] No secrets, no medical claims, sensitive data stays on-device
- [ ] CI is green

## Notes

<!-- Screenshots, follow-ups, or context for reviewers. -->
