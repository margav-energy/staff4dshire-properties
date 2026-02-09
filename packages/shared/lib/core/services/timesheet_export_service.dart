import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';

import '../providers/timesheet_provider.dart';
import '../providers/timesheet_provider.dart' show ApprovalStatus;

class TimesheetExportService {
  static Future<void> exportTimesheet(
    List<TimeEntry> entries,
    String format,
    BuildContext? context,
  ) async {
    switch (format.toUpperCase()) {
      case 'PDF':
        await _exportPDF(entries, context);
        break;
      case 'EXCEL':
        await _exportExcel(entries);
        break;
      case 'CSV':
        await _exportCSV(entries);
        break;
      default:
        throw Exception('Unsupported export format: $format');
    }
  }

  static Future<void> _exportPDF(
    List<TimeEntry> entries,
    BuildContext? context,
  ) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final dateOnlyFormat = DateFormat('dd/MM/yyyy');
    
    // Calculate totals
    Duration totalDuration = Duration.zero;
    for (var entry in entries) {
      if (entry.signOutTime != null) {
        totalDuration += entry.duration;
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Staff4dshire Properties',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Timesheet Report',
                    style: pw.TextStyle(
                      fontSize: 18,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            
            // Summary
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(5),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Total Entries: ${entries.length}',
                        style: pw.TextStyle(fontSize: 12),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Total Hours: ${totalDuration.inHours}h ${totalDuration.inMinutes.remainder(60)}m',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  pw.Text(
                    'Generated: ${dateOnlyFormat.format(DateTime.now())}',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            
            // Table Header
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(1.5),
                4: const pw.FlexColumnWidth(1.5),
                5: const pw.FlexColumnWidth(1),
                6: const pw.FlexColumnWidth(2),
              },
              children: [
                // Header Row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _buildTableCell('Date', isHeader: true),
                    _buildTableCell('Staff Name', isHeader: true),
                    _buildTableCell('Project', isHeader: true),
                    _buildTableCell('Sign In', isHeader: true),
                    _buildTableCell('Sign Out', isHeader: true),
                    _buildTableCell('Hours', isHeader: true),
                    _buildTableCell('Approval', isHeader: true),
                  ],
                ),
                // Data Rows
                ...entries.map((entry) {
                  final duration = entry.signOutTime != null
                      ? entry.duration
                      : Duration.zero;
                  final hours = duration.inHours;
                  final minutes = duration.inMinutes.remainder(60);
                  
                  // Build approval status text
                  String approvalText = 'Pending';
                  if (entry.approvalStatus == ApprovalStatus.approved) {
                    approvalText = entry.approvedBy != null 
                        ? 'Approved by ${entry.approvedBy}'
                        : 'Approved';
                    if (entry.approvedAt != null) {
                      approvalText += '\n${dateOnlyFormat.format(entry.approvedAt!)}';
                    }
                  } else if (entry.approvalStatus == ApprovalStatus.rejected) {
                    approvalText = entry.approvedBy != null 
                        ? 'Rejected by ${entry.approvedBy}'
                        : 'Rejected';
                    if (entry.approvedAt != null) {
                      approvalText += '\n${dateOnlyFormat.format(entry.approvedAt!)}';
                    }
                  }
                  
                  return pw.TableRow(
                    children: [
                      _buildTableCell(dateOnlyFormat.format(entry.signInTime)),
                      _buildTableCell(entry.staffName),
                      _buildTableCell(entry.projectName),
                      _buildTableCell(dateFormat.format(entry.signInTime)),
                      _buildTableCell(
                        entry.signOutTime != null
                            ? dateFormat.format(entry.signOutTime!)
                            : 'In Progress',
                      ),
                      _buildTableCell('${hours}h ${minutes}m'),
                      _buildTableCell(approvalText),
                    ],
                  );
                }).toList(),
              ],
            ),
            
            pw.SizedBox(height: 30),
            
            // Footer
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Text(
              'This is an automated timesheet report generated by Staff4dshire Properties.',
              style: pw.TextStyle(
                fontSize: 8,
                color: PdfColors.grey600,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ];
        },
      ),
    );

    // Print/share PDF
    if (kIsWeb) {
      // For web, use printing package to show preview
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } else {
      // For mobile/desktop, save file
      final output = await getApplicationDocumentsDirectory();
      final file = File('${output.path}/timesheet_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());
      
      if (context != null) {
        // Show success message
        // File is saved to documents directory
      }
    }
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 11 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static Future<void> _exportExcel(List<TimeEntry> entries) async {
    final excel = Excel.createExcel();
    excel.delete('Sheet1'); // Delete default sheet
    final sheet = excel['Timesheet'];
    
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final dateOnlyFormat = DateFormat('dd/MM/yyyy');
    
    // Headers
    sheet.appendRow([
      'Date',
      'Staff Name',
      'Project',
      'Location',
      'Sign In',
      'Sign Out',
      'Hours',
      'Minutes',
      'Approval Status',
      'Approved By',
      'Approved At',
    ]);
    
    // Style header row
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: '#E0E0E0',
    );
    for (var i = 0; i < 11; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).cellStyle = headerStyle;
    }
    
    // Data rows
    for (var entry in entries) {
      final duration = entry.signOutTime != null ? entry.duration : Duration.zero;
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      
      // Build approval status
      String approvalStatus = 'Pending';
      if (entry.approvalStatus == ApprovalStatus.approved) {
        approvalStatus = 'Approved';
      } else if (entry.approvalStatus == ApprovalStatus.rejected) {
        approvalStatus = 'Rejected';
      }
      
      sheet.appendRow([
        dateOnlyFormat.format(entry.signInTime),
        entry.staffName,
        entry.projectName,
        entry.location,
        dateFormat.format(entry.signInTime),
        entry.signOutTime != null
            ? dateFormat.format(entry.signOutTime!)
            : 'In Progress',
        hours,
        minutes,
        approvalStatus,
        entry.approvedBy ?? '',
        entry.approvedAt != null ? dateFormat.format(entry.approvedAt!) : '',
      ]);
    }
    
    // Auto-size columns
    for (var i = 0; i < 11; i++) {
      sheet.setColumnWidth(i, 15);
    }
    
    // Save file
    final bytes = excel.save();
    if (bytes != null) {
      if (kIsWeb) {
        // For web, download file using anchor element
        final blob = bytes;
        // Note: Web file download implementation would go here
        // For now, PDF works best on web via printing package
      } else {
        // For mobile/desktop
        final output = await getApplicationDocumentsDirectory();
        final file = File('${output.path}/timesheet_${DateTime.now().millisecondsSinceEpoch}.xlsx');
        await file.writeAsBytes(bytes);
      }
    }
  }

  static Future<void> _exportCSV(List<TimeEntry> entries) async {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final dateOnlyFormat = DateFormat('dd/MM/yyyy');
    
    final csv = StringBuffer();
    // Headers
    csv.writeln('Date,Staff Name,Project,Location,Sign In,Sign Out,Hours,Minutes,Approval Status,Approved By,Approved At');
    
    // Data rows
    for (var entry in entries) {
      final duration = entry.signOutTime != null ? entry.duration : Duration.zero;
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      
      // Build approval status
      String approvalStatus = 'Pending';
      if (entry.approvalStatus == ApprovalStatus.approved) {
        approvalStatus = 'Approved';
      } else if (entry.approvalStatus == ApprovalStatus.rejected) {
        approvalStatus = 'Rejected';
      }
      
      csv.writeln([
        dateOnlyFormat.format(entry.signInTime),
        '"${entry.staffName.replaceAll('"', '""')}"',
        '"${entry.projectName.replaceAll('"', '""')}"',
        '"${entry.location.replaceAll('"', '""')}"',
        dateFormat.format(entry.signInTime),
        entry.signOutTime != null
            ? dateFormat.format(entry.signOutTime!)
            : 'In Progress',
        hours,
        minutes,
        approvalStatus,
        entry.approvedBy != null ? '"${entry.approvedBy!.replaceAll('"', '""')}"' : '',
        entry.approvedAt != null ? dateFormat.format(entry.approvedAt!) : '',
      ].join(','));
    }
    
    // Save file
    if (kIsWeb) {
      // For web, create download
      // Simplified - would need proper web file download implementation
    } else {
      final output = await getApplicationDocumentsDirectory();
      final file = File('${output.path}/timesheet_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsBytes(csv.toString().codeUnits);
    }
  }
}

