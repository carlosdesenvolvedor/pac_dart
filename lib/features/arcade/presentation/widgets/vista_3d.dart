// Vista 3D real da corrida (Three.js) na web; nas outras plataformas cai
// na vista pseudo-3D em Canvas. Veja `vista_3d_web.dart`.
export 'vista_3d_stub.dart' if (dart.library.js_interop) 'vista_3d_web.dart';
