// Gera os ícones do app (web, Android e iOS) a partir de branding/paclingo-logo.png (ou .jpg).
//
//   swift tool/gerar_icones.swift          (rodar na raiz do projeto)
//
// A logo original vira o "mestre" quadrado de onde saem todos os tamanhos. Se ela vier com os
// cantos arredondados e brancos (como as versões em branding/outras-versoes), eles são preenchidos
// com a cor da borda da própria logo; se já for um quadrado cheio (a atual), nada é mexido.
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let raiz = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
func arq(_ p: String) -> URL { raiz.appendingPathComponent(p) }

/// O azul-marinho das bordas da logo (#0D133C): fundo do ícone adaptativo e margem dos ícones "maskable".
let marinho: (r: UInt8, g: UInt8, b: UInt8) = (0x0D, 0x13, 0x3C)

// MARK: - mestre quadrado, sem cantos brancos

func carregarMestre() -> CGImage {
    let arquivo = ["png", "jpg"].map { arq("branding/paclingo-logo.\($0)") }
        .first { FileManager.default.fileExists(atPath: $0.path) }
    guard let arquivo, let src = CGImageSourceCreateWithURL(arquivo as CFURL, nil),
          let img = CGImageSourceCreateImageAtIndex(src, 0, nil) else {
        fatalError("não achei branding/paclingo-logo.png (rode na raiz do projeto)")
    }
    let w = img.width, h = img.height
    let espaco = CGColorSpaceCreateDeviceRGB()
    let info = CGImageAlphaInfo.noneSkipLast.rawValue
    let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                        space: espaco, bitmapInfo: info)!
    ctx.draw(img, in: CGRect(x: 0, y: 0, width: w, height: h))
    // os pixels viram um array nosso (a memória do contexto não é para ser editada por fora)
    var px = Array(UnsafeBufferPointer(start: ctx.data!.assumingMemoryBound(to: UInt8.self), count: w * h * 4))
    // Os quatro cantos são brancos e arredondados. Acha, por inundação a partir de cada ponta, o branco
    // que está "fora" da logo (quadrado de 25% do lado, para não tocar em branco do desenho) e pinta cada
    // pixel dele com a cor da borda mais próxima, tirada 5 px para dentro (longe do serrilhado).
    func claro(_ x: Int, _ y: Int) -> Bool {
        let i = (y * w + x) * 4
        return min(px[i], px[i + 1], px[i + 2]) > 130
    }
    let limite = w / 4
    var fora = [Bool](repeating: false, count: w * h)
    for (sx, sy) in [(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)] where claro(sx, sy) {
        var fila = [(sx, sy)], k = 0
        fora[sy * w + sx] = true
        while k < fila.count {
            let (x, y) = fila[k]; k += 1
            for (dx, dy) in [(1, 0), (-1, 0), (0, 1), (0, -1)] {
                let nx = x + dx, ny = y + dy
                guard nx >= 0, ny >= 0, nx < w, ny < h, !fora[ny * w + nx] else { continue }
                guard sx == 0 ? nx < limite : nx >= w - limite, sy == 0 ? ny < limite : ny >= h - limite,
                      claro(nx, ny) else { continue }
                fora[ny * w + nx] = true
                fila.append((nx, ny))
            }
        }
    }
    let original = px
    var pintado = [Bool](repeating: false, count: w * h)
    var fila: [(Int, Int)] = []
    for y in 0..<h {
        for x in 0..<w where !fora[y * w + x] {
            // pixel de borda: vizinho de um "fora"
            guard [(1, 0), (-1, 0), (0, 1), (0, -1)].contains(where: { d in
                let nx = x + d.0, ny = y + d.1
                return nx >= 0 && ny >= 0 && nx < w && ny < h && fora[ny * w + nx]
            }) else { continue }
            // 5 px em direção ao centro da logo
            let vx = Double(w) / 2 - Double(x), vy = Double(h) / 2 - Double(y)
            let n = (vx * vx + vy * vy).squareRoot()
            let sx = min(max(x + Int((vx / n * 5).rounded()), 0), w - 1)
            let sy = min(max(y + Int((vy / n * 5).rounded()), 0), h - 1)
            let i = (y * w + x) * 4, q = (sy * w + sx) * 4
            px[i] = original[q]; px[i + 1] = original[q + 1]; px[i + 2] = original[q + 2]
            pintado[y * w + x] = true
            fila.append((x, y))
        }
    }
    // a cor das bordas se espalha para dentro do "fora", pixel a pixel (o mais próximo vence)
    var k = 0
    while k < fila.count {
        let (x, y) = fila[k]; k += 1
        let i = (y * w + x) * 4
        for (dx, dy) in [(1, 0), (-1, 0), (0, 1), (0, -1)] {
            let nx = x + dx, ny = y + dy
            guard nx >= 0, ny >= 0, nx < w, ny < h, fora[ny * w + nx], !pintado[ny * w + nx] else { continue }
            let j = (ny * w + nx) * 4
            px[j] = px[i]; px[j + 1] = px[i + 1]; px[j + 2] = px[i + 2]
            pintado[ny * w + nx] = true
            fila.append((nx, ny))
        }
    }
    guard let prov = CGDataProvider(data: Data(px) as CFData),
          let pronta = CGImage(width: w, height: h, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: w * 4,
                               space: espaco, bitmapInfo: CGBitmapInfo(rawValue: info), provider: prov,
                               decode: nil, shouldInterpolate: true, intent: .defaultIntent) else {
        fatalError("não consegui montar o mestre")
    }
    return pronta
}


// MARK: - desenho e gravação

/// [escala]: quanto da tela a logo ocupa (1 = tudo). [opaco]: pinta o fundo de
/// azul-marinho (ícones sem transparência); senão o resto fica transparente.
func desenhar(_ mestre: CGImage, lado: Int, escala: Double = 1, opaco: Bool = true) -> CGImage {
    let info = opaco ? CGImageAlphaInfo.noneSkipLast.rawValue : CGImageAlphaInfo.premultipliedLast.rawValue
    let ctx = CGContext(data: nil, width: lado, height: lado, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: info)!
    ctx.interpolationQuality = .high
    if opaco {
        // DeviceRGB, o mesmo espaço dos pixels da logo (CGColor(red:…) usa o "Generic RGB" e sai mais claro)
        ctx.setFillColor(CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(),
                                 components: [CGFloat(marinho.r) / 255, CGFloat(marinho.g) / 255, CGFloat(marinho.b) / 255, 1])!)
        ctx.fill(CGRect(x: 0, y: 0, width: lado, height: lado))
    }
    let t = Double(lado) * escala
    let o = (Double(lado) - t) / 2
    ctx.draw(mestre, in: CGRect(x: o, y: o, width: t, height: t))
    return ctx.makeImage()!
}

func gravar(_ img: CGImage, _ caminho: String) {
    let url = arq(caminho)
    try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
        fatalError("não consegui gravar \(caminho)")
    }
    CGImageDestinationAddImage(dest, img, nil)
    guard CGImageDestinationFinalize(dest) else { fatalError("falhou ao gravar \(caminho)") }
    print("  \(caminho) (\(img.width)×\(img.height))")
}

let mestre = carregarMestre()

// MARK: - web
print("web")
gravar(desenhar(mestre, lado: 64), "web/favicon.png")
gravar(desenhar(mestre, lado: 192), "web/icons/Icon-192.png")
gravar(desenhar(mestre, lado: 512), "web/icons/Icon-512.png")
// "maskable": o sistema corta até 20% das bordas, então a logo fica na zona segura
gravar(desenhar(mestre, lado: 192, escala: 0.8), "web/icons/Icon-maskable-192.png")
gravar(desenhar(mestre, lado: 512, escala: 0.8), "web/icons/Icon-maskable-512.png")

// MARK: - Android
print("android")
let densidades: [(String, Int, Int)] = [  // pasta, ícone antigo (48 dp), camada adaptativa (108 dp)
    ("mdpi", 48, 108), ("hdpi", 72, 162), ("xhdpi", 96, 216), ("xxhdpi", 144, 324), ("xxxhdpi", 192, 432),
]
for (d, antigo, camada) in densidades {
    gravar(desenhar(mestre, lado: antigo), "android/app/src/main/res/mipmap-\(d)/ic_launcher.png")
    // 66 dp de 108 aparecem em qualquer máscara (círculo, gota…): a logo ocupa ~60%
    gravar(desenhar(mestre, lado: camada, escala: 0.60, opaco: false),
           "android/app/src/main/res/mipmap-\(d)/ic_launcher_foreground.png")
}
let hex = String(format: "#%02X%02X%02X", marinho.r, marinho.g, marinho.b)
try! """
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">\(hex)</color>
</resources>

""".write(to: arq("android/app/src/main/res/values/ic_launcher_background.xml"), atomically: true, encoding: .utf8)
try? FileManager.default.createDirectory(at: arq("android/app/src/main/res/mipmap-anydpi-v26"), withIntermediateDirectories: true)
try! """
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>

""".write(to: arq("android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml"), atomically: true, encoding: .utf8)
print("  values/ic_launcher_background.xml, mipmap-anydpi-v26/ic_launcher.xml")

// MARK: - iOS (cada tamanho do AppIcon.appiconset; PNG sem transparência)
print("ios")
let pasta = "ios/Runner/Assets.xcassets/AppIcon.appiconset"
let dados = try! Data(contentsOf: arq("\(pasta)/Contents.json"))
let json = try! JSONSerialization.jsonObject(with: dados) as! [String: Any]
for item in json["images"] as! [[String: Any]] {
    guard let nome = item["filename"] as? String,
          let tam = (item["size"] as? String)?.split(separator: "x").first.flatMap({ Double($0) }),
          let esc = (item["scale"] as? String)?.dropLast().description, let e = Double(esc) else { continue }
    gravar(desenhar(mestre, lado: Int((tam * e).rounded())), "\(pasta)/\(nome)")
}

// MARK: - lojas
print("lojas")
gravar(desenhar(mestre, lado: 512), "branding/play-store-512.png")
gravar(desenhar(mestre, lado: 1024), "branding/app-store-1024.png")
