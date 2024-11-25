import 'package:flutter_accessory_manager/src/flutter_accessory_manager_interface.dart';

class AccessoryManagerBluez extends FlutterAccessoryManagerInterface {
  static AccessoryManagerBluez? _instance;
  static AccessoryManagerBluez get instance =>
      _instance ??= AccessoryManagerBluez._();

  AccessoryManagerBluez._();
}
