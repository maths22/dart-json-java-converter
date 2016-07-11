import 'package:barback/barback.dart';
import 'package:code_transformers/resolver.dart';
import 'dart:async';
import 'package:analyzer/dart/element/element.dart';
import 'package:source_maps/refactor.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/analyzer.dart';

class JsonTransformer extends Transformer with ResolverTransformer {

  JsonTransformer.asPlugin() {
    resolvers = new Resolvers(dartSdkDirectory);
  }

  @override
  Future applyResolver(Transform transform, Resolver resolver) {
    String transformPackage = transform.primaryInput.id.package;
    LibraryElement main = resolver.getLibrary(transform.primaryInput.id);
    ClassElement classAnnotation = resolver.getType("rpc_converter.RemoteClass");
    StringBuffer imports = new StringBuffer();
    imports.write('library rpc_json_converters;\n\n');
    imports.write("import 'package:angular2/core.dart';\n");
    imports.write("import '" + resolver.getImportUri(resolver.getType('rpc_converter.ConverterRegistry').library).toString() + "';\n");
    StringBuffer registrations = new StringBuffer();

    StringBuffer output = new StringBuffer();


    resolver.libraries.where((l) => resolver.getSourceAssetId(l)?.package == transformPackage)
        .expand((l) => l.definingCompilationUnit.types)
        .where((e) => e.metadata.any((m) => m.element.enclosingElement == classAnnotation))
        .forEach((e) {
          imports.write("import '${resolver.getImportUri(e.library)}';\n");
          output.write(generateParser(resolver, e));
          registrations.write("ConverterRegistry.register(${e.name}Converter.remoteClass, new ${e.name}().runtimeType, new ${e.name}Converter());\n");
        });


    output = new StringBuffer()..write(imports.toString())..write(output);

    output.write("""
class RpcJsonConverters {


static void runRegistration() {
""");
    output.write(registrations.toString());
    output.write("}\n}\n");
    transform.addOutput(new Asset.fromString(new AssetId(transformPackage, "web/rpc_json_converters.dart"), output.toString()));

    var edit = resolver.createTextEditTransaction(main);
    edit.edit(0,0,"import 'rpc_json_converters.dart';\n");

    main.entryPoint.computeNode().visitChildren(new RewriteMain(edit));

    resolver.getSourceFile(main);

    var print = edit.commit();
    print.build(transform.primaryInput.id.path);

    transform.addOutput(new Asset.fromString(transform.primaryInput.id, print.text));
    return null;
  }

  String generateParser(Resolver resolver, ClassElement c) {
    ClassElement classAnnotation = resolver.getType("rpc_converter.RemoteClass");
    ClassElement fieldAnnotation = resolver.getType("rpc_converter.Remote");
    String remoteClass = c.metadata
        .firstWhere((a) => a.element.enclosingElement == classAnnotation)
        .constantValue.getField("className").toStringValue();
    StringBuffer sb = new StringBuffer();
    sb.write("""
class ${c.name}Converter {
static const String remoteClass = "${remoteClass}";
""");
    StringBuffer writeSb = new StringBuffer();
    writeSb.write("Map<String, dynamic> toJson(${c.name} obj) {\n");
    writeSb.write("Map<String, dynamic> map = new Map();\n");
    StringBuffer readSb = new StringBuffer();
    readSb.write("${c.name} fromJson(Map<String, dynamic> map) {\n");
    readSb.write("${c.name} obj = new ${c.name}();\n");
    c.fields.where((e) => e.metadata.any((m) => m.element.enclosingElement == fieldAnnotation))
      .forEach((e) {
        writeSb.write("map['${e.name}'] = obj.${e.name};\n");
        readSb.write("obj.${e.name} = map['${e.name}'];\n");
      });

    writeSb.write("return map;\n");
    writeSb.write("}\n");
    readSb.write("return obj;\n");
    readSb.write("}\n");
    sb.write(writeSb.toString());
    sb.write(readSb.toString());
    sb.write("}\n");
    return sb.toString();
  }

  Future<bool> shouldApplyResolver(Asset asset) async {
    return true;
  }

  String get allowedExtensions => '.dart';
}

class RewriteMain extends Object with  RecursiveAstVisitor<Object> {
  final TextEditTransaction transaction;

  RewriteMain(this.transaction);

  @override
  Object visitMethodInvocation(MethodInvocation node) {
    if(node.methodName.toString() == 'registerJsonConverters') {
      transaction.edit(node.offset, node.offset + node.length, 'RpcJsonConverters.runRegistration()');
    }

    return super.visitMethodInvocation(node);
  }
}