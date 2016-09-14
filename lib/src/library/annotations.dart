library json_converter_annotations;

class RemoteClass {
  final String className;

  const RemoteClass([this.className]);
}

class RemoteEnum {
  final String className;

  const RemoteEnum([this.className]);
}

class Remote {
  final bool readOnly;

  const Remote({this.readOnly : false});
}

const Remote remote = const Remote();