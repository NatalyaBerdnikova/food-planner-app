# Marketing

App Store and other go-to-market copy, versioned by the app marketing version (`MARKETING_VERSION` in Xcode).

## Layout

```
marketing/
  README.md
  app-store/
    1.0.en-US.md
    1.0.ru.md
```

## Convention

- One file per **app version** + **locale**: `{version}.{locale}.md`
- Locale matches App Store Connect (e.g. `en-US`, `ru`)
- When you ship a new version, copy the previous file, rename to the new version, then edit
- Keep the live App Store Connect fields in sync with the file for that version

## Current

| Version | Locale | File |
| --- | --- | --- |
| 1.0 | en-US | [app-store/1.0.en-US.md](app-store/1.0.en-US.md) |
| 1.0 | ru | [app-store/1.0.ru.md](app-store/1.0.ru.md) |
