enum WindowClass {
  compact,
  medium,
  expanded,
}

class AppBreakpoints {
  const AppBreakpoints._();

  static const double compactMax = 600;
  static const double expandedMin = 900;

  static WindowClass fromWidth(double width) {
    if (width < compactMax) {
      return WindowClass.compact;
    }
    if (width < expandedMin) {
      return WindowClass.medium;
    }
    return WindowClass.expanded;
  }
}
