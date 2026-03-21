# File Converter for macOS

A native macOS application built with **SwiftUI** that converts files locally between all major formats. No internet connection or cloud services required — all processing happens on your Mac.

## Features

- **Image Conversion**: PNG, JPG/JPEG, HEIC/HEIF, BMP, TIFF, GIF, WebP, ICO, SVG
- **Document Conversion**: PDF, RTF, RTFD, TXT, HTML, Markdown, CSV, DOCX
- **Media Conversion**: MOV, MP4, M4V, M4A, AAC, WAV, AIFF, FLAC, AVI
- **PDF → Images**: Renders each PDF page as a separate PNG/JPG/TIFF
- **Drag & Drop**: Drop files directly onto the app
- **Batch Processing**: Convert multiple files at once
- **Local Only**: All conversions happen on-device — no internet required
- **Privacy-first UI**: In-app messaging and a “How conversions work” screen explain local processing

## App Store & privacy (marketing)

When you submit to the App Store, align the product page and **App Privacy** questionnaire with how the app behaves:

- **Data Not Collected** — If the app does not collect analytics, crash data, or personal data, declare that you do not collect data used to track the user, and that no data is linked to the user (or only what is strictly necessary for app functionality, if you add something later).
- **No tracking** — No third-party analytics or ad SDKs means you can state that you do not track users across apps and websites.
- **Optional crash reporting** — If you add crash reporting later, make it **opt-in** in Settings, document it in the privacy screen, and update App Privacy accordingly.

The in-app **How conversions work** screen summarizes Apple frameworks used for conversion; keep that text consistent with your privacy answers.

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 15+ (for building)

## Getting Started

### Build & Run with Xcode

1. Open `Package.swift` in Xcode
2. Select the `FileConverter` scheme
3. Click Run (⌘R)

### Build from Command Line

```bash
swift build
swift run FileConverter
```

## Supported Conversions

| Category   | Input Formats                                                        | Output Formats                                         |
|------------|----------------------------------------------------------------------|--------------------------------------------------------|
| Images     | PNG, JPG, JPEG, HEIC, HEIF, BMP, TIFF, GIF, WebP, ICO               | PNG, JPG, JPEG, HEIC, TIFF, BMP, GIF, WebP, PDF, SVG  |
| Documents  | PDF, RTF, RTFD, TXT, HTML, Markdown (.md), CSV, DOCX                 | PDF, RTF, RTFD, TXT, HTML, Markdown, CSV               |
| PDF→Images | PDF (multi-page)                                                     | PNG, JPG, TIFF (one file per page)                     |
| Media      | MOV, MP4, M4V, M4A, AAC, WAV, AIFF, FLAC (in), AVI (in)             | MOV, MP4, M4V, M4A, AAC, WAV, AIFF                    |

> **Notes:**
> - **DOCX** conversion uses the built-in `textutil` CLI (ships with macOS). Outputs: TXT, HTML, RTF, PDF.
> - **SVG** output embeds the raster image as a base64-encoded PNG inside an SVG wrapper.
> - **FLAC** and **AVI** are supported as _input_ only; native macOS encoding for those formats is not available.
> - **AAC** is exported as an M4A container (standard AAC audio).

## Architecture

- **SwiftUI** — Modern declarative UI framework
- **Core Image & ImageIO** — Image format conversions
- **PDFKit & Core Text** — PDF and document handling
- **AVFoundation** — Audio/video format conversions
- **MVVM** — Clean separation of concerns

## Project Structure

```
FileConverter/
├── FileConverterApp.swift          # App entry point
├── Models/
│   ├── SupportedFormat.swift       # Format definitions & UTType mappings
│   ├── ConversionJob.swift         # Conversion task model
│   └── ConversionError.swift       # Error types
├── Services/
│   ├── ImageConversionService.swift
│   ├── DocumentConversionService.swift
│   ├── MediaConversionService.swift
│   └── ConversionEngine.swift
├── ViewModels/
│   └── ConverterViewModel.swift
├── Views/
│   ├── ContentView.swift
│   ├── DropZoneView.swift
│   ├── FormatPickerView.swift
│   ├── ConversionProgressView.swift
│   ├── FileListView.swift
│   ├── PrivacyOnboardingView.swift
│   └── HowConversionsWorkView.swift
└── Utilities/
    ├── FileTypeDetector.swift
    └── PrivacyOnboardingState.swift
```

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| ⌘O | Open files |
| ⌘⏎ | Start conversion |
| ⌘⇧D | Choose output folder |
| ⌘⌫ | Clear all files |
