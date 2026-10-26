import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../domain/certificado.dart';
import 'site_do_app.dart';

/// 🎓 O PDF do certificado (A4 deitado): as fontes do app (Archivo e Funnel Display, OFL, em assets/fonts/),
/// o nome, o nível, a data, a nota, a carga horária do conteúdo, o código e o QR da página de verificação.
class FontesDoCertificado {
  final pw.Font texto, negrito, titulo;
  const FontesDoCertificado({required this.texto, required this.negrito, required this.titulo});

  static Future<FontesDoCertificado> carregar() async {
    Future<pw.Font> f(String n) async => pw.Font.ttf(await rootBundle.load('assets/fonts/$n.ttf'));
    return FontesDoCertificado(texto: await f('Archivo-400'), negrito: await f('Archivo-700'), titulo: await f('FunnelDisplay-700'));
  }
}

const _azul = PdfColor.fromInt(0xFF0468D7);
const _dourado = PdfColor.fromInt(0xFFFFC73B);
const _tinta = PdfColor.fromInt(0xFF1E1E28);
const _cinza = PdfColor.fromInt(0xFF5C5C6E);

/// Monta o PDF de [c]; [site] é a raiz do site (a verificação fica em `?certificado=<codigo>`).
Future<Uint8List> pdfDoCertificado(Certificado c, FontesDoCertificado f, {String site = siteDoApp}) {
  final url = urlDeVerificacao(site, c.codigo);
  final doc = pw.Document(title: 'Certificado Paclingo ${c.nivel} — ${c.nome}', author: 'Paclingo', creator: 'Paclingo');
  pw.TextStyle st(double size, {pw.Font? font, PdfColor cor = _tinta, double espaco = 0}) =>
      pw.TextStyle(font: font ?? f.texto, fontSize: size, color: cor, letterSpacing: espaco);

  doc.addPage(pw.Page(
    pageFormat: PdfPageFormat.a4.landscape,
    margin: const pw.EdgeInsets.all(28),
    build: (_) => pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all(color: _azul, width: 3)),
      padding: const pw.EdgeInsets.all(6),
      child: pw.Container(
        decoration: pw.BoxDecoration(border: pw.Border.all(color: _dourado, width: 1.5)),
        padding: const pw.EdgeInsets.symmetric(horizontal: 48, vertical: 30),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
          pw.Text('PACLINGO', style: st(13, font: f.negrito, cor: _azul, espaco: 4)),
          pw.SizedBox(height: 4),
          pw.Text('Curso de inglês para brasileiros', style: st(10, cor: _cinza)),
          pw.SizedBox(height: 22),
          pw.Text('Certificado de conclusão', style: st(34, font: f.titulo)),
          pw.SizedBox(height: 18),
          pw.Text('Certificamos que', style: st(12, cor: _cinza)),
          pw.SizedBox(height: 8),
          pw.Text(c.nome, textAlign: pw.TextAlign.center, style: st(28, font: f.negrito, cor: _azul)),
          pw.Container(width: 360, height: 1.2, color: _dourado, margin: const pw.EdgeInsets.only(top: 6, bottom: 12)),
          pw.Text('concluiu o nível', style: st(12, cor: _cinza)),
          pw.SizedBox(height: 6),
          pw.Text(c.nomeDoNivel, style: st(20, font: f.negrito)),
          pw.SizedBox(height: 10),
          pw.Text(
            '${c.licoes} lições · carga horária do conteúdo: ${c.horas} horas · nota na prova final: ${c.nota}%',
            style: st(11),
          ),
          pw.Spacer(),
          pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Expanded(
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('Emitido em ${dataPorExtenso(c.emitidoEm)}', style: st(11, font: f.negrito)),
                pw.SizedBox(height: 4),
                pw.Text('Código de verificação: ${c.codigo}', style: st(11, font: f.negrito, cor: _azul)),
                pw.SizedBox(height: 2),
                pw.Text('Confira em $url', style: st(9, cor: _cinza)),
                pw.SizedBox(height: 10),
                pw.Text(textoDeConteudo, style: st(8, cor: _cinza)),
              ]),
            ),
            pw.SizedBox(width: 20),
            pw.Column(children: [
              pw.BarcodeWidget(barcode: pw.Barcode.qrCode(), data: url, width: 84, height: 84, color: _tinta),
              pw.SizedBox(height: 4),
              pw.Text('verificar', style: st(8, cor: _cinza)),
            ]),
          ]),
        ]),
      ),
    ),
  ));
  return doc.save();
}

/// O nome do arquivo: "certificado-paclingo-b2-PCL-B2-7KQ4-M9XZ.pdf".
String nomeDoArquivo(Certificado c) => 'certificado-paclingo-${c.nivel.toLowerCase()}-${c.codigo}.pdf';
