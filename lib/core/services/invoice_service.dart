import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:ailin_tattileri_app/core/models/order_model.dart';
import 'package:ailin_tattileri_app/core/utils/currency_formatter.dart';

class InvoiceService {
  Future<void> generateAndPrintInvoice(OrderModel order) async {
    final pdf = pw.Document();

    // Load font if necessary for Cyrillic/Kazakh support
    // Using a standard font that supports cyrillic or loading a custom one is crucial.
    // 'OpenSans' is often available or we use fallback.
    // For simplicity in this environment, we attempt a standard load or rely on Printing default.
    // However, fast implementation often requires loading a font asset.
    // We will try using standard PdfGoogleFonts which downloads it, or just standard theme.
    // WARNING: Default PDF fonts don't support Cyrillic. We need a font.
    final font = await PdfGoogleFonts.openSansRegular();
    final fontBold = await PdfGoogleFonts.openSansBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Ailin Tattileri',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Накладная',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Order Info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Заказ №: ${order.id.substring(0, 5).toUpperCase()}',
                      ),
                      pw.Text(
                        'Дата: ${DateFormat('dd.MM.yyyy HH:mm').format(order.createdAt)}',
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Клиент: ${order.userName}'),
                      pw.Text('Телефон: ${order.userPhone}'),
                      pw.Text('Адрес: ${order.userAddress}'),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 30),

              // Items Table
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Товар',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Кол-во',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Цена',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Сумма',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  // Items
                  ...order.items.map((item) {
                    final name = item['name'] as String? ?? 'Товар';
                    final quantity = item['quantity'] as int? ?? 1;
                    final price = (item['price'] as num? ?? 0).toDouble();
                    final total = price * quantity;

                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(name),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('$quantity'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('${CurrencyFormatter.format(price)}'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('${CurrencyFormatter.format(total)}'),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),

              if (order.returnItems != null &&
                  order.returnItems!.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                pw.Text(
                  'Возвраты',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.red,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    // Return Table Header
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.red100,
                      ),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            'Товар',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            'Кол-во',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            'Причина',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            'Сумма (вычет)',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    // Return Items
                    ...order.returnItems!.map((item) {
                      final productData =
                          item['product'] as Map<String, dynamic>? ?? {};
                      final name = productData['name'] as String? ?? 'Товар';
                      final quantity = item['quantity'] as int? ?? 1;
                      final price = (productData['price'] as num? ?? 0)
                          .toDouble();
                      final reason = item['reason'] as String? ?? 'expired';
                      final total = price * quantity;

                      String reasonText = "Срок годности";
                      if (reason == 'unsold') reasonText = "Не продано";
                      if (reason == 'damaged') reasonText = "Брак";

                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(name),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text('$quantity'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(reasonText),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(
                              '-${CurrencyFormatter.format(total)}',
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ],
              pw.SizedBox(height: 20),

              // Total calculation section
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  if (order.refundAmount > 0) ...[
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Text('Сумма заказа: '),
                        pw.Text(
                          '${CurrencyFormatter.format(order.totalAmount + order.refundAmount)} ₸',
                        ),
                      ],
                    ),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Возвраты: ',
                          style: const pw.TextStyle(color: PdfColors.red),
                        ),
                        pw.Text(
                          '-${CurrencyFormatter.format(order.refundAmount)} ₸',
                          style: const pw.TextStyle(color: PdfColors.red),
                        ),
                      ],
                    ),
                    pw.Divider(),
                  ],
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Text(
                        'ИТОГО К ОПЛАТЕ: ',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        '${CurrencyFormatter.format(order.totalAmount)} ₸',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 50),

              // Signatures
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    children: [
                      pw.Container(
                        width: 150,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(bottom: pw.BorderSide()),
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text('Подпись менеджера'),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Container(
                        width: 150,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(bottom: pw.BorderSide()),
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text('Подпись клиента'),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'invoice_${order.id.substring(0, 5)}.pdf',
    );
  }
}
