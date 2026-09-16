/// Native HEIC/HEIF (and other codec-unsupported) → orientation-aware PNG.
///
/// Default is the IO MethodChannel implementation; web hosts use the stub
/// (Photo Studio still prefers [browserImageDecodeAdapter] on web).
export 'native_image_normalize_adapter_io.dart'
    if (dart.library.html) 'native_image_normalize_adapter_stub.dart';
