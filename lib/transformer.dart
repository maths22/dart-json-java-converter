import 'package:barback/barback.dart';
import 'package:code_transformers/resolver.dart';
import 'dart:async';
import 'package:analyzer/dart/element/element.dart';
import 'package:json_java_converter/src/transformer/converter_generator.dart';
import 'package:source_maps/refactor.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/analyzer.dart';
import 'package:dart_style/dart_style.dart';


class JsonTransformer extends Transformer with ResolverTransformer {

  JsonTransformer.asPlugin() {
    resolvers = new Resolvers(dartSdkDirectory);
  }

  @override
  Future applyResolver(Transform transform, Resolver resolver) {
    String transformPackage = transform.primaryInput.id.package;
    LibraryElement main = resolver.getLibrary(transform.primaryInput.id);
    ClassElement classAnnotation = resolver.getType("json_converter_annotations.RemoteClass");
    StringBuffer imports = new StringBuffer();
    imports.write('library rpc_json_converters;\n\n');
    imports.write("import '" + resolver.getImportUri(resolver.getType('json_converter_registry.ConverterRegistry').library).toString() + "';\n");
    StringBuffer registrations = new StringBuffer();

    StringBuffer output = new StringBuffer();

    ConverterGenerator converterGenerator = new ConverterGenerator(resolver);

    resolver.libraries.where((l) => resolver.getSourceAssetId(l)?.package == transformPackage)
        .expand((l) => l.definingCompilationUnit.types)
        .where((e) => e.metadata.any((m) => m.element?.enclosingElement == classAnnotation))
        .forEach((e) {
          imports.write("import '${resolver.getImportUri(e.library)}';\n");
          output.write(converterGenerator.generateParser(e));
          registrations.write("ConverterRegistry.register(${e.name}Converter.remoteClass, new ${e.name}().runtimeType, new ${e.name}Converter());\n");
        });


    output = new StringBuffer()..write(imports.toString())..write(output);

    output.write("""
class RpcJsonConverters {

static void runRegistration() {
""");
    output.write(registrations.toString());
    output.write("}\n}\n");
    transform.addOutput(new Asset.fromString(new AssetId(transformPackage, "web/rpc_json_converters.dart"),
        new DartFormatter(pageWidth: 120).format(output.toString())));

    var edit = resolver.createTextEditTransaction(main);
    edit.edit(0,0,"import 'rpc_json_converters.dart';\n");

    main.entryPoint.computeNode().visitChildren(new RewriteMain(edit));

    var print = edit.commit();
    print.build(transform.primaryInput.id.path);

    transform.addOutput(new Asset.fromString(transform.primaryInput.id, print.text));
    return null;
  }

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