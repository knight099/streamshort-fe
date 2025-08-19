enum Environment {
  development,
  staging,
  production,
}

class EnvironmentConfig {
  static Environment _environment = Environment.development;
  
  static void setEnvironment(Environment env) {
    _environment = env;
  }
  
  static Environment get environment => _environment;
  
  static String get apiBaseUrl {
    switch (_environment) {
      case Environment.development:
        return 'http://localhost:8080/';
      case Environment.staging:
        return 'https://staging-api.streamshort.in/';
      case Environment.production:
        return 'https://api.streamshort.in/';
    }
  }
  
  static bool get isDevelopment => _environment == Environment.development;
  static bool get isStaging => _environment == Environment.staging;
  static bool get isProduction => _environment == Environment.production;
  
  static Duration get connectionTimeout {
    switch (_environment) {
      case Environment.development:
        return const Duration(seconds: 10);
      case Environment.staging:
      case Environment.production:
        return const Duration(seconds: 30);
    }
  }
  
  static Duration get receiveTimeout {
    switch (_environment) {
      case Environment.development:
        return const Duration(seconds: 10);
      case Environment.staging:
      case Environment.production:
        return const Duration(seconds: 30);
    }
  }
  
  static bool get enableLogging {
    switch (_environment) {
      case Environment.development:
        return true;
      case Environment.staging:
        return true;
      case Environment.production:
        return false;
    }
  }
}
