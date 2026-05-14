import 'package:flutter/material.dart';
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
  bool _isExporting = false;

  Future<void> _exportPdf() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final pdf = pw.Document();
      final generatedAt = DateTime.now().toLocal();
      final formattedDate =
          '${generatedAt.year}-${generatedAt.month.toString().padLeft(2, '0')}-${generatedAt.day.toString().padLeft(2, '0')}';
      final accentColor = _certificateAccentColor;
      final baseFont = _isRtl
          ? await PdfGoogleFonts.cairoRegular()
          : await PdfGoogleFonts.robotoRegular();
      final boldFont = _isRtl
          ? await PdfGoogleFonts.cairoBold()
          : await PdfGoogleFonts.robotoBold();
      final logoImage = await imageFromAssetBundle('assets/images/lingova_logo.png');
      final titleStyle = pw.TextStyle(
        font: boldFont,
        fontSize: 32,
        fontWeight: pw.FontWeight.bold,
      );
      final secondaryStyle = pw.TextStyle(
        font: baseFont,
        fontSize: 14,
        color: PdfColors.grey700,
        height: 1.7,
      );
      final labelStyle = pw.TextStyle(
        font: baseFont,
        fontSize: 12,
        color: PdfColors.grey600,
      );
      final valueStyle = pw.TextStyle(
        font: boldFont,
        fontSize: 12,
        fontWeight: pw.FontWeight.bold,
      );
      final pdfRows = [
        _pdfRow(
          _translate(ar: 'اسم الطالب', en: 'Student Name', de: 'Studentenname'),
          widget.result.studentName,
          labelStyle: labelStyle,
          valueStyle: valueStyle,
        ),
        _pdfSpacer,
        _pdfRow(
          _translate(ar: 'الكورس', en: 'Course', de: 'Kurs'),
          widget.result.courseTitle,
          labelStyle: labelStyle,
          valueStyle: valueStyle,
        ),
        _pdfSpacer,
        _pdfRow(
          _translate(ar: 'المستوى', en: 'Level', de: 'Niveau'),
          widget.result.levelTitle,
          labelStyle: labelStyle,
          valueStyle: valueStyle,
        ),
        _pdfSpacer,
        _pdfRow(
          _translate(ar: 'اللغة', en: 'Language', de: 'Sprache'),
          widget.result.courseLanguage,
          labelStyle: labelStyle,
          valueStyle: valueStyle,
        ),
        _pdfSpacer,
        _pdfRow(
          _translate(ar: 'نوع الامتحان', en: 'Exam Type', de: 'Prüfungstyp'),
          _translatedExamType,
          labelStyle: labelStyle,
          valueStyle: valueStyle,
        ),
        _pdfSpacer,
        _pdfRow(
          _translate(ar: 'النتيجة', en: 'Score', de: 'Punktzahl'),
          '${widget.result.score}% (${widget.result.correctAnswers}/${widget.result.totalQuestions})',
          labelStyle: labelStyle,
          valueStyle: valueStyle,
        ),
        _pdfSpacer,
        _pdfRow(
          _translate(
            ar: 'تاريخ الإنجاز',
            en: 'Completion Date',
            de: 'Abschlussdatum',
          ),
          widget.result.submittedAtLabel,
          labelStyle: labelStyle,
          valueStyle: valueStyle,
        ),
      ];

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Stack(
              children: [
                pw.Positioned.fill(
                  child: pw.Container(
                    decoration: pw.BoxDecoration(
                      gradient: pw.LinearGradient(
                        colors: [PdfColors.grey100, PdfColors.white],
                        begin: pw.Alignment.topLeft,
                        end: pw.Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
                pw.Positioned(
                  right: 24,
                  top: 24,
                  child: pw.Container(
                    width: 110,
                    height: 110,
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      shape: pw.BoxShape.circle,
                      border: pw.Border.all(color: accentColor, width: 2),
                    ),
                    child: pw.Center(
                      child: pw.Column(
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.Container(
                            width: 54,
                            height: 54,
                            decoration: pw.BoxDecoration(
                              shape: pw.BoxShape.circle,
                              border: pw.Border.all(
                                color: accentColor,
                                width: 1.5,
                              ),
                            ),
                            child: pw.Center(
                              child: pw.Image(
                                logoImage,
                                width: 38,
                                height: 38,
                              ),
                            ),
                          ),
                          pw.SizedBox(height: 8),
                          pw.Text(
                            'Lingova',
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                              font: boldFont,
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                pw.Positioned.fill(
                  child: pw.Opacity(
                    opacity: 0.08,
                    child: pw.Center(
                      child: pw.Text(
                        _watermarkText,
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 110,
                          color: PdfColors.grey300,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(28),
                  child: pw.Directionality(
                    textDirection: _isRtl
                        ? pw.TextDirection.rtl
                        : pw.TextDirection.ltr,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  'Lingova App',
                                  style: pw.TextStyle(
                                    font: boldFont,
                                    color: accentColor,
                                    fontSize: 18,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                pw.SizedBox(height: 4),
                                pw.Text(
                                  _certificateBrandLabel,
                                  style: pw.TextStyle(
                                    font: baseFont,
                                    fontSize: 10,
                                    color: PdfColors.grey700,
                                  ),
                                ),
                              ],
                            ),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: pw.BoxDecoration(
                                color: accentColor,
                                borderRadius: pw.BorderRadius.circular(8),
                              ),
                              child: pw.Text(
                                _finalSealLabel,
                                style: pw.TextStyle(
                                  font: boldFont,
                                  fontSize: 12,
                                  color: PdfColors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 28),
                        pw.Center(
                          child: pw.Text(
                            _pageTitle,
                            textAlign: pw.TextAlign.center,
                            style: titleStyle,
                          ),
                        ),
                        pw.SizedBox(height: 10),
                        pw.Center(
                          child: pw.Text(
                            _pageSubtitle,
                            textAlign: pw.TextAlign.center,
                            style: secondaryStyle,
                          ),
                        ),
                        pw.SizedBox(height: 28),
                        pw.Center(
                          child: pw.Text(
                            _honoreeLabel,
                            style: pw.TextStyle(
                              font: baseFont,
                              fontSize: 12,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 10),
                        pw.Center(
                          child: pw.Text(
                            widget.result.studentName,
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                              font: boldFont,
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 24),
                        pw.Divider(color: PdfColors.grey300, thickness: 1),
                        pw.SizedBox(height: 20),
                        ...pdfRows,
                        pw.SizedBox(height: 30),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  _issueDateLabel,
                                  style: pw.TextStyle(
                                    font: baseFont,
                                    fontSize: 10,
                                    color: PdfColors.grey700,
                                  ),
                                ),
                                pw.SizedBox(height: 4),
                                pw.Text(
                                  formattedDate,
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
                                pw.Text(
                                  _authorizedSignatureLabel,
                                  style: pw.TextStyle(
                                    font: baseFont,
                                    fontSize: 10,
                                    color: PdfColors.grey700,
                                  ),
                                ),
                                pw.SizedBox(height: 12),
                                pw.Container(
                                  width: 140,
                                  height: 1,
                                  color: PdfColors.grey700,
                                ),
                                pw.SizedBox(height: 4),
                                pw.Text(
                                  _directorLabel,
                                  style: pw.TextStyle(
                                    font: boldFont,
                                    fontSize: 12,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        pw.Spacer(),
                        pw.Divider(color: PdfColors.grey300),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          _footerNote,
                          style: pw.TextStyle(
                            font: baseFont,
                            fontSize: 10,
                            color: PdfColors.grey700,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );

      final bytes = await pdf.save();
      await Printing.sharePdf(
        bytes: bytes,
        filename:
            'Certificate_${widget.result.courseTitle}_${widget.result.levelTitle}.pdf',
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'حدث خطأ أثناء إنشاء الملف. حاول مرة أخرى.',
            textAlign: TextAlign.right,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  bool get _isEnglish {
    return widget.result.courseLanguage.toLowerCase().contains('english');
  }

  bool get _isGerman {
    final language = widget.result.courseLanguage.toLowerCase();
    return language.contains('german') || language.contains('deutsch');
  }

  bool get _isRtl => !_isEnglish && !_isGerman;

  TextDirection get _textDirection =>
      _isRtl ? TextDirection.rtl : TextDirection.ltr;

  String get _translatedExamType {
    if (widget.result.type == 'level_final') {
      return _translate(
        ar: 'نهاية مستوى',
        en: 'Final Level',
        de: 'Abschlusslevel',
      );
    }

    return _translate(ar: 'كويز', en: 'Quiz', de: 'Quiz');
  }

  PdfColor get _certificateAccentColor {
    if (_isEnglish) {
      return PdfColors.blue;
    }
    if (_isGerman) {
      return PdfColors.teal;
    }
    return PdfColors.orange;
  }

  String _translate({
    required String ar,
    required String en,
    required String de,
  }) {
    if (_isEnglish) return en;
    if (_isGerman) return de;
    return ar;
  }

  String get _pageTitle {
    if (_isEnglish) {
      return widget.result.passed
          ? (widget.result.type == 'level_final'
                ? 'Level Completion Certificate'
                : 'Exam Completion Certificate')
          : 'Exam Participation Certificate';
    }
    if (_isGerman) {
      return widget.result.passed
          ? (widget.result.type == 'level_final'
                ? 'Zertifikat zum Kursabschluss'
                : 'Zertifikat zum Prüfungserfolg')
          : 'Teilnahmezertifikat';
    }
    return widget.result.passed
        ? (widget.result.type == 'level_final'
              ? 'شهادة إتمام المستوى'
              : 'شهادة إتمام الامتحان')
        : 'شهادة أداء الامتحان';
  }

  String get _pageSubtitle {
    if (_isEnglish) {
      return widget.result.passed
          ? (widget.result.type == 'level_final'
                ? 'This certificate confirms the student successfully completed the final level.'
                : 'This certificate confirms the student successfully completed the exam.')
          : 'This certificate confirms the student participated in the exam.';
    }
    if (_isGerman) {
      return widget.result.passed
          ? (widget.result.type == 'level_final'
                ? 'Dieses Zertifikat bestätigt, dass der Schüler das Abschlusslevel erfolgreich abgeschlossen hat.'
                : 'Dieses Zertifikat bestätigt, dass der Schüler die Prüfung erfolgreich abgeschlossen hat.')
          : 'Dieses Zertifikat bestätigt, dass der Schüler an der Prüfung teilgenommen hat.';
    }
    return widget.result.passed
        ? (widget.result.type == 'level_final'
              ? 'تشهد هذه الشهادة بأن الطالب أكمل هذا المستوى بنجاح.'
              : 'تشهد هذه الشهادة بأن الطالب أكمل هذا الامتحان بنجاح.')
        : 'تشهد هذه الشهادة بأن الطالب أتم هذا الامتحان.';
  }

  String get _certificateBrandLabel {
    return _translate(
      ar: 'شهادة أكاديمية رسمية',
      en: 'Official Academic Certificate',
      de: 'Offizielles Akademisches Zertifikat',
    );
  }

  String get _finalSealLabel {
    return _translate(ar: 'نهائي', en: 'FINAL', de: 'FINAL');
  }

  String get _watermarkText {
    return _translate(ar: 'شهادة', en: 'CERTIFICATE', de: 'ZERTIFIKAT');
  }

  String get _honoreeLabel {
    return _translate(
      ar: 'تُمنح هذه الشهادة إلى:',
      en: 'This certificate is awarded to:',
      de: 'Dieses Zertifikat wird verliehen an:',
    );
  }

  String get _issueDateLabel {
    return _translate(
      ar: 'تاريخ الإصدار',
      en: 'Issue Date',
      de: 'Ausstellungsdatum',
    );
  }

  String get _authorizedSignatureLabel {
    return _translate(
      ar: 'توقيع المعتمد',
      en: 'Authorized Signature',
      de: 'Offizielle Unterschrift',
    );
  }

  String get _directorLabel {
    return _translate(
      ar: 'مدير Lingova',
      en: 'Lingova Director',
      de: 'Lingova Direktor',
    );
  }

  String get _footerNote {
    return _translate(
      ar: 'هذه الشهادة صالحة للاستخدام الأكاديمي والتوثيق داخل منصة Lingova.',
      en: 'This certificate is valid for academic and verification purposes within the Lingova platform.',
      de: 'Dieses Zertifikat ist für akademische Zwecke und die Verifikation auf der Lingova-Plattform gültig.',
    );
  }

  pw.Widget get _pdfSpacer => pw.SizedBox(height: 12);

  pw.Widget _pdfRow(
    String label,
    String value, {
    required pw.TextStyle labelStyle,
    required pw.TextStyle valueStyle,
  }) {
    final labelWidget = pw.Text('$label:', style: labelStyle);
    final valueWidget = pw.Expanded(
      child: pw.Text(
        value.isNotEmpty ? value : '-',
        textAlign: _isRtl ? pw.TextAlign.right : pw.TextAlign.left,
        style: valueStyle,
      ),
    );

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: _isRtl
          ? [valueWidget, pw.SizedBox(width: 12), labelWidget]
          : [labelWidget, pw.SizedBox(width: 12), valueWidget],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFinal = widget.result.type == 'level_final';

    return Directionality(
      textDirection: _textDirection,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _translate(
              ar: 'شهادة الطالب',
              en: 'Student Certificate',
              de: 'Studentenzertifikat',
            ),
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(22),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.workspace_premium_rounded,
                      size: 56,
                      color: AppColors.orange,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _pageTitle,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _pageSubtitle,
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textMuted,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    _buildRow(
                      _translate(
                        ar: 'اسم الطالب',
                        en: 'Student Name',
                        de: 'Studentenname',
                      ),
                      widget.result.studentName,
                    ),
                    const SizedBox(height: 14),
                    _buildRow(
                      _translate(ar: 'الكورس', en: 'Course', de: 'Kurs'),
                      widget.result.courseTitle,
                    ),
                    const SizedBox(height: 14),
                    _buildRow(
                      _translate(ar: 'المستوى', en: 'Level', de: 'Niveau'),
                      widget.result.levelTitle,
                    ),
                    const SizedBox(height: 14),
                    _buildRow(
                      _translate(ar: 'اللغة', en: 'Language', de: 'Sprache'),
                      widget.result.courseLanguage,
                    ),
                    const SizedBox(height: 14),
                    _buildRow(
                      _translate(
                        ar: 'نوع الامتحان',
                        en: 'Exam Type',
                        de: 'Prüfungstyp',
                      ),
                      _translatedExamType,
                    ),
                    const SizedBox(height: 14),
                    _buildRow(
                      _translate(ar: 'النتيجة', en: 'Score', de: 'Punktzahl'),
                      '${widget.result.score}% (${widget.result.correctAnswers}/${widget.result.totalQuestions})',
                    ),
                    const SizedBox(height: 14),
                    _buildRow(
                      _translate(
                        ar: 'تاريخ الإنجاز',
                        en: 'Completion Date',
                        de: 'Abschlussdatum',
                      ),
                      widget.result.submittedAtLabel,
                    ),
                    const SizedBox(height: 28),
                    const Divider(),
                    const SizedBox(height: 18),
                    Text(
                      _translate(
                        ar: 'توقيع التطبيق',
                        en: 'App Signature',
                        de: 'App-Signatur',
                      ),
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Lingova App',
                      style: TextStyle(
                        color: AppColors.orange,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
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
                    _isExporting
                        ? _translate(
                            ar: 'جارٍ التحميل...',
                            en: 'Downloading...',
                            de: 'Wird heruntergeladen...',
                          )
                        : _translate(
                            ar: 'تحميل شهادة PDF',
                            en: 'Download PDF Certificate',
                            de: 'PDF-Zertifikat herunterladen',
                          ),
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
                    _translate(
                      ar: 'النتائج المعروضة هنا للكويزات، ولكن الشهادة الرسمية متاحة فقط لامتحانات نهاية المستوى.',
                      en: 'This view is for quizzes only; official certificates are available only for final level exams.',
                      de: 'Diese Ansicht ist nur für Quizze; offizielle Zertifikate sind nur für Abschlussprüfungen verfügbar.',
                    ),
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
      style: const TextStyle(fontSize: 15, color: Colors.black54),
    );
    final valueWidget = Expanded(
      child: Text(
        value.isNotEmpty ? value : '-',
        textAlign: _isRtl ? TextAlign.right : TextAlign.left,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
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
