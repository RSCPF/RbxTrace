# Changelog

All notable changes to RbxTrace will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.0] - 2025-09-25

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
