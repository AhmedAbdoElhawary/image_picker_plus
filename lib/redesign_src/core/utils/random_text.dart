import 'dart:math' show Random;

class RandomString {
  static String generate() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    Random random = Random();
    return List.generate(20, (index) => chars[random.nextInt(chars.length)]).join();
  }
}
