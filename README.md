# JsonJavaConverter

A library for converting between Dart types and Java types, using JSON serilaization

## Usage

A simple example, with one serializable entity (Note that any property )
you want to process must be annotated with `Remote()`, and any class with `RemoteClass()`
and the Java class name.

season.dart:

    import 'package:json_java_converter/json_java_converter.dart';

    @RemoteClass("com.maths22.ftc.entities.Season")
    class Season {
      @Remote()
      String id;

      @Remote()
      String name;

      @Remote()
      String slug;

      @Remote()
      String year;



    }

To initialize the converters, you must call `registerJsonConverters()` in the
main method of your application (typically in `web/main.dart`).

Add `json_java_converter` to the list of transformers in your `pubspec.yaml`.

Usage of converter:

    converter = new RpcConverter();
    converter.convertToJson(a); //Produces list/map/native type
    converter.convertFromJson(response); //Produces Dart object