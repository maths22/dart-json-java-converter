import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:code_transformers/resolver.dart';

class ConverterGenerator {
  final Resolver _resolver;
  final ClassElement _classAnnotation;
  final ClassElement _enumAnnotation;
  final ClassElement _fieldAnnotation;


  ConverterGenerator(Resolver resolver):
        _resolver = resolver,
        _classAnnotation = resolver.getType("json_converter_annotations.RemoteClass"),
        _enumAnnotation = resolver.getType("json_converter_annotations.RemoteEnum"),
        _fieldAnnotation = resolver.getType("json_converter_annotations.Remote");



  String generateParser(ClassElement classElement) {


    StringBuffer converter = _converterInit(classElement);
    StringBuffer toJson = _toJsonInit(classElement);
    StringBuffer fromJson = _fromJsonInit(classElement);

    classElement.fields
        .where((e) => _hasAnnotation(e, _fieldAnnotation))
        .forEach((e) {
          if(_isDateTimeField(e)) {
            _writeDateTimeConverter(e, toJson, fromJson);
          } else if(_isEnumField(e)) {
            _writeEnumConverter(e, toJson, fromJson);
          } else {
            _writeGenericConverter(e, toJson, fromJson);
          }

        });

    classElement.allSupertypes
        .expand((t) => t.accessors)
        .map((t) => t.variable)
        .where((e) => _hasAnnotation(e, _fieldAnnotation))
        .forEach((e) {
          if(_isDateTimeField(e)) {
            _writeDateTimeConverter(e, toJson, fromJson);
          } else if(_isEnumField(e)) {
            _writeEnumConverter(e, toJson, fromJson);
          } else {
            _writeGenericConverter(e, toJson, fromJson);
          }

        });

    return _converterFinish(converter, _toJsonFinish(toJson), _fromJsonFinish(fromJson));
  }

  DartObject _getConstantValue(Element e, ClassElement annotation) {
    return e.metadata
        .firstWhere((m) => m.constantValue.type.isAssignableTo(annotation.type))
        .constantValue;
  }

  bool _hasAnnotation(Element e, ClassElement annotation) {
    return e.metadata
        .any((m) => m.constantValue.type.isAssignableTo(annotation.type));
  }

  bool _isDateTimeField(VariableElement e) {
    return e.type.isSubtypeOf(_resolver.getType("dart.core.DateTime").type) && !e.type.isDynamic;
  }

  bool _isEnumField(VariableElement e) {
    return _hasAnnotation(e.type.element, _enumAnnotation);
  }

  StringBuffer _converterInit(ClassElement classElement) {
    String remoteClassName = _getConstantValue(classElement, _classAnnotation)
        .getField("className").toStringValue();

    StringBuffer sb = new StringBuffer();
    sb.write("class ${classElement.name}Converter {\n");
    sb.write("static const String remoteClass = \"${remoteClassName}\";\n");
    return sb;
  }

  String _converterFinish(StringBuffer sb, String toJson, String fromJson) {
    sb.write(toJson);
    sb.write(fromJson);
    sb.write("}\n");
    return sb.toString();
  }

  StringBuffer _toJsonInit(ClassElement classElement) {
    StringBuffer sb = new StringBuffer();
    sb.write("Map<String, dynamic> toJson(${classElement.name} obj) {\n");
    sb.write("Map<String, dynamic> map = new Map();\n");
    return sb;
  }

  StringBuffer _fromJsonInit(ClassElement classElement) {
    StringBuffer sb = new StringBuffer();
    sb.write("${classElement.name} fromJson(Map<String, dynamic> map) {\n");
    sb.write("${classElement.name} obj = new ${classElement.name}();\n");
    return sb;
  }

  void _writeDateTimeConverter(FieldElement e, StringBuffer toJson, StringBuffer fromJson) {
    toJson.write("if(obj.${e.name} != null) {map['${e.name}'] = obj.${e.name};}\n");
    fromJson.write("if(map.containsKey('${e.name}')) {obj.${e.name} = DateTime.parse(map['${e.name}']);}\n");
  }

  void _writeEnumConverter(FieldElement e, StringBuffer toJson, StringBuffer fromJson) {
    String remoteName = _getConstantValue(e.type.element, _enumAnnotation).getField("className").toStringValue();
    toJson.write("if(obj.${e.name} != null) {map['${e.name}'] = ['$remoteName', enumToString(obj.${e.name})];}\n");
    fromJson.write("if(map.containsKey('${e.name}')) {\n" +
        "assert(map['${e.name}'][0] == '$remoteName');\n" +
        "obj.${e.name} = enumFromString(${e.type.name}.values, map['${e.name}'][1]);\n}\n");
  }

  void _writeGenericConverter(FieldElement e, StringBuffer toJson, StringBuffer fromJson) {
    toJson.write("if(obj.${e.name} != null) {map['${e.name}'] = obj.${e.name};}\n");
    fromJson.write("if(map.containsKey('${e.name}')) {obj.${e.name} = map['${e.name}'];}\n");
  }

  String _toJsonFinish(StringBuffer sb) {
    sb.write("return map;\n");
    sb.write("}\n");
    return sb.toString();
  }

  String _fromJsonFinish(StringBuffer sb) {
    sb.write("return obj;\n");
    sb.write("}\n");
    return sb.toString();
  }
}
