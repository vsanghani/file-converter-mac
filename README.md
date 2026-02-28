# File Converter for macOS

A native macOS application built with **SwiftUI** that converts files locally between all major formats. No internet connection or cloud services required — all processing happens on your Mac.

## Features

- **Image Conversion**: PNG, JPG/JPEG, HEIC/HEIF, BMP, TIFF, GIF, WebP, ICO
- **Document Conversion**: PDF, RTF, RTFD, TXT, HTML
- **Media Conversion**: MOV, MP4, M4V, M4A, WAV, AIFF
- **Drag & Drop**: Drop files directly onto the app
- **Batch Processing**: Convert multiple files at once
- **Local Only**: All conversions happen on-device

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

| Category   | Input Formats                                     | Output Formats                          |
|------------|---------------------------------------------------|-----------------------------------------|
| Images     | PNG, JPG, JPEG, HEIC, HEIF, BMP, TIFF, GIF, WebP, ICO | PNG, JPG, JPEG, HEIC, TIFF, BMP, GIF, PDF |
| Documents  | PDF, RTF, RTFD, TXT, HTML                         | PDF, RTF, TXT, HTML                     |
| Media      | MOV, MP4, M4V, M4A, WAV, AIFF                     | MOV, MP4, M4V, M4A, WAV, AIFF          |

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
│   └── FileListView.swift
└── Utilities/
    └── FileTypeDetector.swift
```

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| ⌘O | Open files |
| ⌘⏎ | Start conversion |
| ⌘⇧D | Choose output folder |
| ⌘⌫ | Clear all files |
