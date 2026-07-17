# App Store Submission Pack

This folder contains copy-ready App Store Connect material for the first iOS submission.

## Files

- `metadata.zh-Hans.md`: Chinese App Store listing copy, keywords, category, age rating notes, and screenshot mapping.
- `review-notes.zh-Hans.md`: App Review notes explaining the offline two-player flow and camera/photo usage.
- `privacy-policy.zh-Hans.md`: Privacy policy draft to publish at the final Privacy Policy URL.
- `support.zh-Hans.md`: Support page draft to publish at the final Support URL.

## Account-side items still required

- Confirm the final Bundle ID and Apple Developer Team in Xcode/App Store Connect.
- Publish `privacy-policy.zh-Hans.md` and `support.zh-Hans.md` to public HTTPS URLs.
- Fill App Privacy as "No, we do not collect data from this app" if the shipped app remains offline-only and uses avatars only on device.
- Upload a signed Release build through Xcode Organizer or `xcodebuild -exportArchive` after team signing is configured.

References:

- App information: https://developer.apple.com/help/app-store-connect/reference/app-information/app-information/
- App privacy: https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/
- Privacy manifest / required reason API: https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api
- Screenshot specifications: https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/
