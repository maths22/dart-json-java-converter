library rpc_converter;

class RemoteClass {
  final String className;

  const RemoteClass([this.className]);
}

class Remote {
  const Remote();
}

const Remote remote = const Remote();

class ConverterRegistry {


  static Map<String, dynamic> javaClasses = new Map();
  static Map<Type, String> dartClasses = new Map();

  static void register(String s, Type t, cv) {
    javaClasses[s] = cv;
    dartClasses[t] = s;
  }
}

class RpcConverter {

  //TODO: support sets, queues?
  dynamic convertFromJson(dynamic obj) {
    if(obj is List) {
      return obj.map((o) => convertFromJson(o)).toList();
    } else if (obj is Map) {
      Map ret = new Map();
      obj.forEach((k, v) => ret[convertFromJson(k)] = convertFromJson(v));
      if (obj['@class'] != null) {
        return ConverterRegistry.javaClasses[obj['@class']].fromJson(ret);
      } else {
        return ret;
      }
    } else {
      return obj;
    }
  }

  dynamic convertToJson(dynamic obj) {
    if(obj is List) {
      return obj.map((o) => convertToJson(o)).toList();
    } else if (obj is Map) {
      Map ret = new Map();
      obj.forEach((k, v) => ret[convertToJson(k)] = convertToJson(v));
      return ret;
    } else if (obj is DateTime) {
      return [obj.millisecondsSinceEpoch];
    } else if (ConverterRegistry.dartClasses[obj.runtimeType] != null) {
      Map ret = ConverterRegistry.javaClasses[ConverterRegistry.dartClasses[obj.runtimeType]].toJson(obj);
      ret.forEach((k, v) => ret[convertToJson(k)] = convertToJson(v));
      ret['@class'] = ConverterRegistry.dartClasses[obj.runtimeType];
      return ret;
    } else {
      return obj;
    }
  }
}

registerJsonConverters() {
  throw new Exception("The json_java_converter transformer must be listed in your pubspec.yaml");
}
