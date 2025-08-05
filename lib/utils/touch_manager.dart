class TouchManager {
  static bool isTouchInProgress = false;

  static bool canProcessTouch() {
    if (isTouchInProgress) return false;
    isTouchInProgress = true;
    return true;
  }

  static void touchProcessed() {
    isTouchInProgress = false;
  }
}
