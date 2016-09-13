library json_converter_enum_utils;

String enumToString(dynamic val) {
  String rawString = val.toString();
  int dotPos = rawString.lastIndexOf('.');
  return rawString.substring(dotPos + 1);
}

dynamic enumFromString(List types, String val) {
  for(var t in types) {
    if(enumToString(t) == val) {
      return t;
    }
  }
  return null;
}