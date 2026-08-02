abstract class PowerService {
  Future<bool> isBatteryOptimizationIgnored();
  Future<int> getBatteryLevel();
}

class AndroidPowerService implements PowerService {
  @override
  Future<bool> isBatteryOptimizationIgnored() async {
    // Default system fallback for platform contract
    return true;
  }

  @override
  Future<int> getBatteryLevel() async {
    return 100;
  }
}
