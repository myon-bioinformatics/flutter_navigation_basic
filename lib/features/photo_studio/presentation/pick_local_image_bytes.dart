export 'pick_local_image_bytes_stub.dart'
    if (dart.library.html) 'pick_local_image_bytes_web.dart'
    if (dart.library.io) 'pick_local_image_bytes_io.dart';
