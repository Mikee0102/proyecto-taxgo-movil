class AppRoutes {
  static const home = '/home';
  static const login = '/auth/login';
  static const register = '/auth/register';
  static const protectedPaths = {home};

  static String safeReturnTo(Object? destination) {
    if (destination is String && protectedPaths.contains(destination)) {
      return destination;
    }
    return home;
  }
}
