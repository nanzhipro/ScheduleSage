# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**ScheduleSage** is an intelligent calendar event creation tool for macOS that helps users quickly identify and import schedule information from various sources. It's a native SwiftUI application with sophisticated OCR, voice recognition, and AI-powered event parsing capabilities.

- **Platform**: macOS 12+
- **UI Framework**: SwiftUI with AppKit integration
- **Architecture**: MVVM (Model-View-ViewModel)
- **Language**: Swift with modern concurrency (async/await)

## Common Commands

### Building and Running
```bash
# Build the project
swift build

# Run tests
swift test

# Clean build
swift package reset && swift build
```

### Development with Xcode
The project uses Swift Package Manager but can be opened in Xcode:
- Open `Package.swift` in Xcode to work with the full project
- Use Xcode's built-in build and test commands
- Product → Build (⌘B) to build
- Product → Test (⌘U) to run tests

## Architecture Overview

### Core Components

#### **AddScheduleViewModel** (`ViewModels/AddScheduleViewModel.swift`)
The main orchestrator with 970+ lines handling:
- Clipboard monitoring and content processing
- Drag & drop functionality for images
- OCR processing coordination
- LLM integration for natural language processing
- Voice recognition management
- Calendar operations and event creation
- State management for the entire app workflow

#### **Service Layer** (`Services/`)
- **LLMEventProcessor**: AI-powered event extraction from natural language text
- **DeviceInfoService**: System information gathering for analytics
- **LoggerService**: Centralized logging with CocoaLumberjack
- **NotificationManager**: macOS system notifications
- **ThemeManager**: App appearance and dark mode support
- **LaunchManager**: App lifecycle and launch-at-login functionality

#### **Shared Modules** (`Shared/`)
- **QuestOCR/**: Complete OCR system for image text extraction
- **QuestSpeech/**: Voice recognition with Tencent Cloud integration
- **QuestWebCrawler/**: Web content extraction and parsing

### Data Flow

1. **Input Sources**: Clipboard → Manual Text → Image OCR → Voice → Web Crawling
2. **Processing**: Raw content → LLM parsing → Structured event data
3. **Output**: Calendar events → System calendar integration

### Key Dependencies

- **Kingfisher**: Image downloading and caching
- **Alamofire**: Network requests for API calls
- **CocoaLumberjack**: Logging framework
- **SwiftDate**: Date manipulation and formatting
- **RevenueCat**: In-app purchases and subscriptions
- **Sentry**: Error tracking and analytics
- **AudioKit**: Audio processing for voice recognition

## Development Guidelines

### Code Organization
- **Views**: Place UI components in `Views/Components/` for reusability
- **ViewModels**: Business logic in `ViewModels/` following MVVM pattern
- **Models**: Data structures in `Models/` with proper JSON parsing
- **Services**: Shared services in `Services/` with protocol-oriented design

### Modern Swift Patterns
- Use `async/await` for all asynchronous operations
- Apply `@MainActor` for UI thread safety
- Implement proper error handling with custom error types
- Follow protocol-oriented programming principles

### State Management
- Centralized loading states via `LoadingManager` in `Utils/Loading/`
- Use `@Published` properties for reactive UI updates
- Implement proper cleanup in `deinit` methods
- Handle keyboard monitoring and global shortcuts properly

### Localization
- Support Chinese, English, and Japanese languages
- Place localization files in `Resources/Localization/`
- Use proper localization keys for all user-facing text

### Security & Privacy
- All OCR processing happens locally (no data uploading)
- Proper entitlements for calendar, microphone, and file access
- Secure API key management (never commit secrets)
- Follow Apple's App Sandbox requirements

## Key Technical Considerations

### Performance
- Implement lazy loading for heavy operations
- Use background queues for OCR and voice processing
- Proper memory management with cleanup
- Rate limiting for API calls

### Error Handling
- Comprehensive error types for different domains
- Graceful degradation when services fail
- User-friendly error messages
- Detailed logging for debugging

### Testing
- Unit tests for core business logic
- UI tests for critical user flows
- Mock external dependencies (Tencent Cloud, RevenueCat)
- Test with various input formats and edge cases

## Common Patterns

### Async Operations
```swift
@MainActor
func processContent() async {
    // Always use @MainActor for UI updates
    // Use async/await for network calls and heavy processing
}
```

### Error Handling
```swift
// Use custom error types for different domains
enum ScheduleProcessingError: Error {
    case invalidFormat
    case networkFailure
    case ocrProcessingFailed
}
```

### Component Design
- Create reusable components in `Views/Components/`
- Use clear protocols for component interfaces
- Follow SwiftUI best practices for state management
- Implement proper accessibility support

## Development Workflow

1. **Feature Development**: Start with ViewModels for business logic
2. **UI Implementation**: Create SwiftUI views following design system
3. **Integration**: Connect services and handle state management
4. **Testing**: Write unit tests and verify functionality
5. **Localization**: Add proper localization support
6. **Error Handling**: Implement comprehensive error handling

Remember to always use the Chain-of-Thought approach when implementing complex features, breaking down problems into smaller, manageable steps.