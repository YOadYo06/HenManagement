int calculateComfortScore({
  required double light,
  required double noise,
  required double temperature,
}) {
  var lightScore = 0;
  var noiseScore = 0;
  var tempScore = 0;

  if (light < 200) {
    lightScore = _mapRange(light, 0, 200, 0, 50);
  } else if (light >= 200 && light < 300) {
    lightScore = _mapRange(light, 200, 300, 50, 75);
  } else if (light >= 300 && light <= 500) {
    lightScore = _mapRange(light, 300, 500, 90, 100);
  } else {
    lightScore = _mapRange(light, 500, 1000, 90, 75);
    if (lightScore < 75) lightScore = 75;
  }

  if (noise < 30) {
    noiseScore = 100;
  } else if (noise >= 30 && noise <= 50) {
    noiseScore = _mapRange(noise, 30, 50, 100, 90);
  } else if (noise > 50 && noise <= 70) {
    noiseScore = _mapRange(noise, 50, 70, 75, 50);
  } else {
    noiseScore = _mapRange(noise, 70, 100, 50, 0);
  }

  if (temperature < 18) {
    tempScore = _mapRange(temperature, 10, 18, 40, 60);
  } else if (temperature >= 18 && temperature < 20) {
    tempScore = _mapRange(temperature, 18, 20, 70, 85);
  } else if (temperature >= 20 && temperature <= 24) {
    tempScore = _mapRange(temperature, 20, 24, 90, 100);
  } else {
    tempScore = _mapRange(temperature, 24, 30, 80, 60);
    if (tempScore < 60) tempScore = 60;
  }

  final score = (lightScore * 0.4) + (noiseScore * 0.3) + (tempScore * 0.3);
  return score.round().clamp(0, 100);
}

int _mapRange(double value, double inMin, double inMax, int outMin, int outMax) {
  if (inMax - inMin == 0) return outMin;
  final ratio = (value - inMin) / (inMax - inMin);
  return (outMin + (ratio * (outMax - outMin))).round();
}
