import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/app_colors.dart';
import '../../data/models/exam.dart';

class CertificatePage extends StatefulWidget {
  final ExamResult result;

  const CertificatePage({super.key, required this.result});

  @override
  State<CertificatePage> createState() => _CertificatePageState();
}

class _CertificatePageState extends State<CertificatePage> {
  static const _downloadsChannel = MethodChannel('lingova/downloads');

  bool _isExporting = false;

  Future<void> _exportPdf() async {
    setState(() => _isExporting = true);

    try {
      final pdf = pw.Document();
      final logoImage = await imageFromAssetBundle(
        'assets/images/lingova_logo.png',
      );
      final regularFont = _isRtl
          ? await PdfGoogleFonts.cairoRegular()
          : await PdfGoogleFonts.robotoRegular();
      final boldFont = _isRtl
          ? await PdfGoogleFonts.cairoBold()
          : await PdfGoogleFonts.robotoBold();
      final accent = _accentColor;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(28),
          build: (context) {
            return pw.Directionality(
              textDirection: _pdfTextDirection,
              child: pw.Container(
                padding: const pw.EdgeInsets.all(26),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  border: pw.Border.all(color: accent, width: 2),
                ),
                child: pw.Stack(
                  children: [
                    pw.Positioned.fill(
                      child: pw.Center(
                        child: pw.Opacity(
                          opacity: 0.075,
                          child: pw.Image(
                            logoImage,
                            width: 360,
                            height: 360,
                            fit: pw.BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                      children: [
                        _pdfHeader(logoImage, regularFont, boldFont, accent),
                        pw.SizedBox(height: 22),
                        pw.Text(
                          _copy.certificateTitle,
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 32,
                            color: PdfColors.grey900,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 10),
                        pw.Text(
                          _copy.subtitle,
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            font: regularFont,
                            fontSize: 13,
                            color: PdfColors.grey700,
                            height: 1.4,
                          ),
                        ),
                        pw.SizedBox(height: 22),
                        pw.Text(
                          _copy.awardedTo,
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            font: regularFont,
                            fontSize: 12,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          widget.result.studentName,
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 28,
                            color: accent,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 22),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 26,
                            vertical: 18,
                          ),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.grey50,
                            border: pw.Border.all(color: PdfColors.grey300),
                            borderRadius: pw.BorderRadius.circular(12),
                          ),
                          child: pw.Column(
                            children: [
                              _pdfInfoRow(
                                _copy.course,
                                widget.result.courseTitle,
                                regularFont,
                                boldFont,
                              ),
                              _pdfGap,
                              _pdfInfoRow(
                                _copy.level,
                                widget.result.levelTitle,
                                regularFont,
                                boldFont,
                              ),
                              _pdfGap,
                              _pdfInfoRow(
                                _copy.language,
                                widget.result.courseLanguage,
                                regularFont,
                                boldFont,
                              ),
                              _pdfGap,
                              _pdfInfoRow(
                                _copy.examDate,
                                _examDateLabel,
                                regularFont,
                                boldFont,
                              ),
                              _pdfGap,
                              _pdfInfoRow(
                                _copy.score,
                                _scoreLabel,
                                regularFont,
                                boldFont,
                              ),
                            ],
                          ),
                        ),
                        pw.Spacer(),
                        _pdfFooter(regularFont, boldFont),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      final bytes = await pdf.save();
      final fileName = _safeFileName(
        'Lingova_Certificate_${widget.result.studentName}_${widget.result.courseTitle}_${widget.result.levelTitle}.pdf',
      );
      final savedPath = await _downloadsChannel.invokeMethod<String>(
        'savePdf',
        {'fileName': fileName, 'bytes': bytes},
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _copy.savedMessage(savedPath ?? 'Downloads/Lingova/$fileName'),
            textAlign: TextAlign.right,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_copy.saveError}\n$error',
            textAlign: TextAlign.right,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  pw.Widget _pdfHeader(
    pw.ImageProvider logoImage,
    pw.Font regularFont,
    pw.Font boldFont,
    PdfColor accent,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Row(
          children: [
            pw.Container(
              width: 58,
              height: 58,
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                shape: pw.BoxShape.circle,
                border: pw.Border.all(color: accent, width: 1.4),
              ),
              child: pw.Image(logoImage),
            ),
            pw.SizedBox(width: 10),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Lingova',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 18,
                    color: accent,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  _copy.officialCertificate,
                  style: pw.TextStyle(
                    font: regularFont,
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: pw.BoxDecoration(
            color: accent,
            borderRadius: pw.BorderRadius.circular(999),
          ),
          child: pw.Text(
            _copy.passed,
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 11,
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _pdfInfoRow(
    String label,
    String value,
    pw.Font regularFont,
    pw.Font boldFont,
  ) {
    final labelWidget = pw.Text(
      label,
      style: pw.TextStyle(
        font: regularFont,
        color: PdfColors.grey700,
        fontSize: 11,
      ),
    );
    final valueWidget = pw.Expanded(
      child: pw.Text(
        value.isEmpty ? '-' : value,
        textAlign: _isRtl ? pw.TextAlign.left : pw.TextAlign.right,
        style: pw.TextStyle(
          font: boldFont,
          color: PdfColors.grey900,
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );

    return pw.Row(
      children: _isRtl
          ? [valueWidget, pw.SizedBox(width: 16), labelWidget]
          : [labelWidget, pw.SizedBox(width: 16), valueWidget],
    );
  }

  pw.Widget _pdfFooter(pw.Font regularFont, pw.Font boldFont) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              _copy.issueDate,
              style: pw.TextStyle(
                font: regularFont,
                fontSize: 10,
                color: PdfColors.grey700,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              _todayLabel,
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Container(width: 150, height: 1, color: PdfColors.grey700),
            pw.SizedBox(height: 6),
            pw.Text(
              _copy.signature,
              style: pw.TextStyle(
                font: regularFont,
                fontSize: 10,
                color: PdfColors.grey700,
              ),
            ),
            pw.Text(
              'Lingova',
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  bool get _isEnglish {
    final language = widget.result.courseLanguage.toLowerCase();
    return language.contains('english') ||
        language.contains('eng') ||
        language.contains('الإنجليزية') ||
        language.contains('الانجليزية');
  }

  bool get _isGerman {
    final language = widget.result.courseLanguage.toLowerCase();
    return language.contains('german') ||
        language.contains('deutsch') ||
        language.contains('الألمانية') ||
        language.contains('الالمانية');
  }

  bool get _isRtl => !_isEnglish && !_isGerman;

  TextDirection get _textDirection =>
      _isRtl ? TextDirection.rtl : TextDirection.ltr;

  pw.TextDirection get _pdfTextDirection =>
      _isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr;

  PdfColor get _accentColor {
    if (_isEnglish) return PdfColors.blue700;
    if (_isGerman) return PdfColors.teal700;
    return PdfColors.orange700;
  }

  _CertificateCopy get _copy {
    if (_isEnglish) return _CertificateCopy.english();
    if (_isGerman) return _CertificateCopy.german();
    return _CertificateCopy.arabic();
  }

  String get _scoreLabel {
    return '${widget.result.score}% (${widget.result.correctAnswers}/${widget.result.totalQuestions})';
  }

  String get _examDateLabel {
    final parsed = DateTime.tryParse(widget.result.submittedAt)?.toLocal();
    if (parsed == null) return widget.result.submittedAtLabel;
    return _formatDateTime(parsed);
  }

  String get _todayLabel => _formatDate(DateTime.now());

  String _formatDateTime(DateTime date) {
    final dateText = _formatDate(date);
    final timeText =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return '$dateText - $timeText';
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _safeFileName(String value) {
    return value
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .trim();
  }

  pw.Widget get _pdfGap => pw.SizedBox(height: 12);

  @override
  Widget build(BuildContext context) {
    final isFinal = widget.result.type == 'level_final';

    return Directionality(
      textDirection: _textDirection,
      child: Scaffold(
        appBar: AppBar(title: Text(_copy.screenTitle)),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(22),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.orange.withValues(alpha: .35),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .12),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: DefaultTextStyle.merge(
                  style: const TextStyle(color: Color(0xFF111827)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.workspace_premium_rounded,
                        size: 56,
                        color: AppColors.orange,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        _copy.certificateTitle,
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _copy.subtitle,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF667085),
                          height: 1.6,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      const Divider(color: Color(0xFFE5E7EB)),
                      const SizedBox(height: 16),
                      _buildRow(_copy.studentName, widget.result.studentName),
                      const SizedBox(height: 14),
                      _buildRow(_copy.course, widget.result.courseTitle),
                      const SizedBox(height: 14),
                      _buildRow(_copy.level, widget.result.levelTitle),
                      const SizedBox(height: 14),
                      _buildRow(_copy.language, widget.result.courseLanguage),
                      const SizedBox(height: 14),
                      _buildRow(_copy.examDate, _examDateLabel),
                      const SizedBox(height: 14),
                      _buildRow(_copy.score, _scoreLabel),
                      const SizedBox(height: 28),
                      const Divider(color: Color(0xFFE5E7EB)),
                      const SizedBox(height: 18),
                      Text(
                        _copy.signature,
                        style: const TextStyle(
                          color: Color(0xFF667085),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Lingova',
                        style: TextStyle(
                          color: AppColors.orange,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              if (isFinal)
                FilledButton.icon(
                  onPressed: _isExporting ? null : _exportPdf,
                  icon: _isExporting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download_rounded),
                  label: Text(
                    _isExporting ? _copy.downloading : _copy.download,
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    _copy.finalOnlyNotice,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    final labelWidget = Text(
      '$label:',
      style: const TextStyle(fontSize: 15, color: Color(0xFF667085)),
    );
    final valueWidget = Expanded(
      child: Text(
        value.isNotEmpty ? value : '-',
        textAlign: _isRtl ? TextAlign.right : TextAlign.left,
        style: const TextStyle(
          color: Color(0xFF111827),
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _isRtl
          ? [valueWidget, const SizedBox(width: 12), labelWidget]
          : [labelWidget, const SizedBox(width: 12), valueWidget],
    );
  }
}

class _CertificateCopy {
  final String screenTitle;
  final String officialCertificate;
  final String certificateTitle;
  final String subtitle;
  final String awardedTo;
  final String passed;
  final String studentName;
  final String course;
  final String level;
  final String language;
  final String examDate;
  final String score;
  final String issueDate;
  final String signature;
  final String download;
  final String downloading;
  final String finalOnlyNotice;
  final String saveError;
  final String Function(String path) savedMessage;

  const _CertificateCopy({
    required this.screenTitle,
    required this.officialCertificate,
    required this.certificateTitle,
    required this.subtitle,
    required this.awardedTo,
    required this.passed,
    required this.studentName,
    required this.course,
    required this.level,
    required this.language,
    required this.examDate,
    required this.score,
    required this.issueDate,
    required this.signature,
    required this.download,
    required this.downloading,
    required this.finalOnlyNotice,
    required this.saveError,
    required this.savedMessage,
  });

  factory _CertificateCopy.arabic() {
    return _CertificateCopy(
      screenTitle: 'شهادة الطالب',
      officialCertificate: 'شهادة أكاديمية رسمية',
      certificateTitle: 'شهادة إتمام المستوى',
      subtitle: 'تشهد منصة Lingova بأن الطالب أكمل امتحان نهاية المستوى بنجاح.',
      awardedTo: 'تمنح هذه الشهادة إلى',
      passed: 'ناجح',
      studentName: 'اسم الطالب',
      course: 'الكورس',
      level: 'المستوى',
      language: 'اللغة',
      examDate: 'تاريخ الامتحان',
      score: 'درجة الامتحان',
      issueDate: 'تاريخ الإصدار',
      signature: 'توقيع Lingova',
      download: 'تحميل شهادة PDF',
      downloading: 'جار التحميل...',
      finalOnlyNotice:
          'الشهادة الرسمية متاحة فقط لامتحانات نهاية المستوى.',
      saveError: 'حدث خطأ أثناء حفظ الشهادة. حاول مرة أخرى.',
      savedMessage: (path) => 'تم حفظ الشهادة في $path',
    );
  }

  factory _CertificateCopy.english() {
    return _CertificateCopy(
      screenTitle: 'Student Certificate',
      officialCertificate: 'Official Academic Certificate',
      certificateTitle: 'Level Completion Certificate',
      subtitle:
          'Lingova certifies that the student successfully completed the final level exam.',
      awardedTo: 'This certificate is awarded to',
      passed: 'PASSED',
      studentName: 'Student Name',
      course: 'Course',
      level: 'Level',
      language: 'Language',
      examDate: 'Exam Date',
      score: 'Exam Score',
      issueDate: 'Issue Date',
      signature: 'Lingova Signature',
      download: 'Download PDF Certificate',
      downloading: 'Downloading...',
      finalOnlyNotice:
          'Official certificates are available only for final level exams.',
      saveError: 'Could not save the certificate. Please try again.',
      savedMessage: (path) => 'Certificate saved to $path',
    );
  }

  factory _CertificateCopy.german() {
    return _CertificateCopy(
      screenTitle: 'Studentenzertifikat',
      officialCertificate: 'Offizielles Akademisches Zertifikat',
      certificateTitle: 'Zertifikat zum Levelabschluss',
      subtitle:
          'Lingova bestätigt, dass der Schüler die Abschlussprüfung des Levels erfolgreich bestanden hat.',
      awardedTo: 'Dieses Zertifikat wird verliehen an',
      passed: 'BESTANDEN',
      studentName: 'Name des Schülers',
      course: 'Kurs',
      level: 'Level',
      language: 'Sprache',
      examDate: 'Prüfungsdatum',
      score: 'Prüfungsergebnis',
      issueDate: 'Ausstellungsdatum',
      signature: 'Lingova Unterschrift',
      download: 'PDF-Zertifikat herunterladen',
      downloading: 'Wird heruntergeladen...',
      finalOnlyNotice:
          'Offizielle Zertifikate sind nur für Abschlussprüfungen verfügbar.',
      saveError: 'Das Zertifikat konnte nicht gespeichert werden.',
      savedMessage: (path) => 'Zertifikat gespeichert unter $path',
    );
  }
}
