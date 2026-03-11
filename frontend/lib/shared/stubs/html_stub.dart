// Stub for dart:html to allow cross-platform compilation
class Window {
  Location get location => Location();
}

class Location {
  String hash = '';
}

final window = Window();
