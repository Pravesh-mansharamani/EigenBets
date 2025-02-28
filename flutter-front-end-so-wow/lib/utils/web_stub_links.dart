// Stub implementation for uni_links on web
import 'dart:async';

// Stub for getInitialLink
Future<String?> getInitialLink() async {
  return null;
}

// Stub for linkStream
Stream<String?> get linkStream {
  // Return an empty stream that will never emit anything
  final controller = StreamController<String?>.broadcast();
  // Close immediately to avoid memory leaks
  controller.close();
  return controller.stream;
} 