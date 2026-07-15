class AccessibilityPreferences {
  const AccessibilityPreferences({
    this.lowStimulation = false,
    this.reduceMotion = false,
    this.soundEnabled = false,
    this.vibrationEnabled = true,
    this.textScale = 1.0,
  });

  final bool lowStimulation;
  final bool reduceMotion;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final double textScale;
}
