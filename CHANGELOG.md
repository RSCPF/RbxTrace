# Changelog## [0.0.4] - 2025-10-01



All notable changes to this project will be documented in this file.### Changes

- fix: clean up build artifacts and update exclusion list in wally.toml

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),

and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).### Commit Details

- **Version bump**: patch

## [Unreleased]- **Build date**: 2025-10-01

- **Commit**: 01d0451

### Added

- Initial release of RbxTrace logging system## [0.0.3] - 2025-10-01

- Comprehensive logging with 6 levels (TRACE, DEBUG, INFO, WARN, ERROR, FATAL)

- Real-time GUI monitoring### Changes

- DataStore persistence- chore: test actions

- Webhook integration

- Client-Server communication via Red### Commit Details

- Performance monitoring utilities- **Version bump**: patch

- Group rank authentication for dev GUI- **Build date**: 2025-10-01

- Rate limiting and memory management- **Commit**: e451bca

- Export functionality (Pastebin, JSON, CSV, text)

- Search and filtering capabilities## [0.0.2] - 2025-10-01

### Changes


### Commit Details
- **Version bump**: patch
- **Build date**: 2025-10-01
- **Commit**: 77c5dad

# Changelog

All notable changes to RbxTrace will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-09-25

### Added

- Initial release of RbxTrace as a Wally package
- 6-level logging system (TRACE, DEBUG, INFO, WARN, ERROR, FATAL)
- Multi-tier storage backends (Memory, DataStore, Webhooks)
- Real-time developer GUI with filtering and search
- Client-server log transmission via Red networking
- Discord webhook integration for error alerts
- Automatic script detection and line number tracking
- Performance monitoring and metrics
- Log export functionality (JSON, CSV, Text, Pastebin)
- Group rank-based authentication for developer features
- Rate limiting and spam prevention
- Memory management with automatic log rotation
- Comprehensive configuration system
- Full documentation and usage examples
- Framework integration patterns
- Global convenience functions
- Async processing for performance optimization
- Rich metadata support
- Export capabilities for external analysis

### Features

- **Core Logging**: 6 log levels with intelligent routing
- **Storage**: Memory cache, DataStore persistence, webhook alerts
- **GUI**: Real-time developer interface with F9 keybind
- **Network**: Secure client-server communication
- **Performance**: Async processing, batching, memory management
- **Security**: Rate limiting, input validation, authentication
- **Export**: Multiple formats including Pastebin integration
- **Monitoring**: Built-in performance tracking and system stats
- **Configuration**: Fully customizable via config object
- **Integration**: Easy framework integration patterns

### Dependencies

- Red ^2.3.2 (for networking)

### Documentation

- Complete README with setup instructions
- API reference documentation
- Usage examples and integration patterns
- Configuration guide
- Troubleshooting section
- Performance optimization tips
