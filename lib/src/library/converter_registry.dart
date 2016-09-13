library json_converter_registry;

class ConverterRegistry {

  static Map<String, dynamic> javaClasses = new Map();
  static Map<Type, String> dartClasses = new Map();

  static void register(String s, Type t, cv) {
    javaClasses[s] = cv;
    dartClasses[t] = s;
  }
}

registerJsonConverters() {
  throw new Exception("The json_java_converter transformer must be listed in your pubspec.yaml");
}
