# EigenBet Frontend Development Guide

## Build/Testing Commands
- Run app: `flutter run`
- Run all tests: `flutter test`
- Run single test: `flutter test test/widget_test.dart`
- Run specific test: `flutter test --name="test_name" test/widget_test.dart`
- Analyze code: `flutter analyze`
- Format code: `flutter format lib/`

## Code Style Guidelines
- **Imports**: Dart/Flutter imports first, third-party packages next, local imports last
- **Types**: Strong typing throughout - all variables, parameters, and returns have explicit types
- **Naming**: Classes in PascalCase, variables/functions in camelCase, private members with underscore
- **Widgets**: Use StatelessWidget/StatefulWidget appropriately, prefer const constructors
- **Error Handling**: Try/catch for platform code, proper null safety with ? and ! operators
- **Documentation**: Comments for complex logic, document non-obvious parameters
- **State Management**: Provider pattern with clean separation between UI and business logic
- **Organization**: Code organized by feature directories (models, screens, services, widgets)
- **Formatting**: 2-space indentation, Dart standard formatting

For crypto wallet integration questions, refer to the Coinbase SDK documentation (CoinbaseCDK1_merged.pdf).