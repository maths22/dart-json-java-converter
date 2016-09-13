library json_converter_rpc;

import 'package:json_java_converter/src/library/converter_registry.dart';
import 'package:logging/logging.dart';

class RpcConverter {
  Logger _log = new Logger("RpcConverter");

  //TODO: support sets, queues?
  dynamic convertFromJson(dynamic obj) {
    if(obj is List) {
      return obj.map((o) => convertFromJson(o)).toList();
    } else if (obj is Map) {
      Map ret = new Map();
      obj.forEach((k, v) => ret[convertFromJson(k)] = convertFromJson(v));
      String type = obj['@class'];
      if (type != null) {
        var converter = ConverterRegistry.javaClasses[type];
        if(converter == null) {
          _log.warning('No registration for type $type');
          return ret;
        }
        return converter.fromJson(ret);
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
      return obj.toIso8601String();
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