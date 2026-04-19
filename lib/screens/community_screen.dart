import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../services/rag_service.dart';
import '../services/datepalm_api.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  int _tab = 0;
  int _selectedCat = 0;
  final _cats = [
    '🏭 Industry',
    '💧 Water',
    '🗑️ Waste',
    '🌫️ Air',
    '🌾 Agriculture',
    '🌿 Other'
  ];
  final _chatCtrl = TextEditingController();
  List<String> _projects = [];
  String? _selectedProject;
  final _ragMessages = <RAGMessage>[];
  final _ragInputCtrl = TextEditingController();
  bool _ragLoading = false;
  List<Source> _currentSources = [];
  bool _showSources = false;

  // Date Palm Disease Detection state
  late DatePalmApi _datePalmApi;
  File? _selectedImage;
  Uint8List? _imageBytes;
  Map<String, dynamic>? _diseaseResult;
  Uint8List? _segmentedImage;
  bool _isAnalyzing = false;
  String? _analysisError;

  @override
  void initState() {
    super.initState();
    _datePalmApi = DatePalmApi('http://172.20.10.2:8002');
    _loadProjects();
  }

  void _loadProjects() async {
    final projects = await RAGService.getProjects();
    setState(() {
      _projects = projects;
      if (projects.isNotEmpty) {
        _selectedProject = projects[0];
      }
    });
  }

  void _sendRAGMessage() async {
    if (_ragInputCtrl.text.isEmpty) return;
    final message = _ragInputCtrl.text;
    _ragInputCtrl.clear();
    setState(() {
      _ragMessages.add(RAGMessage(text: message, isUser: true, timestamp: DateTime.now()));
      _ragLoading = true;
      _showSources = false;
    });

    final response = await RAGService.chat(
      message: message,
      project: _selectedProject,
      topK: 5,
      history: _ragMessages
          .where((m) => !m.isUser || _ragMessages.indexOf(m) < _ragMessages.length - 1)
          .map((m) => {'role': m.isUser ? 'user' : 'assistant', 'content': m.text})
          .toList(),
    );

    if (response != null) {
      setState(() {
        _ragMessages.add(RAGMessage(
          text: response.answer,
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _currentSources = response.sources;
        _ragLoading = false;
        _showSources = response.sources.isNotEmpty;
      });
    } else {
      setState(() {
        _ragMessages.add(RAGMessage(
          text: 'Sorry, I could not process your request. Please try again.',
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _ragLoading = false;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImage = File(pickedFile.path);
          _imageBytes = bytes;
          _diseaseResult = null;
          _segmentedImage = null;
          _analysisError = null;
        });
      }
    } catch (e) {
      print('❌ Error picking image: $e');
      setState(() {
        _analysisError = 'Failed to pick image: $e';
      });
    }
  }

  Future<void> _analyzeDisease() async {
    if (_imageBytes == null) return;
    setState(() {
      _isAnalyzing = true;
      _analysisError = null;
    });

    try {
      final result = await _datePalmApi.predictDisease(_imageBytes!);
      
      // Also get the segmented image
      Uint8List? segmented;
      try {
        segmented = await _datePalmApi.segment(_imageBytes!);
        print('✅ Segmentation successful');
      } catch (e) {
        print('⚠️ Segmentation error (non-critical): $e');
      }
      
      setState(() {
        _diseaseResult = result;
        _segmentedImage = segmented;
        _isAnalyzing = false;
      });
      print('✅ Disease analysis complete');
    } catch (e) {
      print('❌ Disease analysis error: $e');
      setState(() {
        _analysisError = 'Analysis failed: $e';
        _isAnalyzing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            _tabs(),
            Expanded(child: _body()),
            if (_tab == 1) _chatInputBar(),
            if (_tab == 2) _ragInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _header() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(bottom: BorderSide(color: AppColors.border)),
    ),
    child: Row(
      children: [
        Text(
          'Community',
          style: GoogleFonts.syne(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.add, size: 18, color: AppColors.green400),
        ),
      ],
    ),
  );

  Widget _tabs() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
    child: Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.green50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.green100),
      ),
      child: Row(children: [_tabItem(0, 'Signal'), _tabItem(1, 'Chat'), _tabItem(2, 'Investments')]),
    ),
  );

  Widget _tabItem(int idx, String label) => Expanded(
    child: GestureDetector(
      onTap: () => setState(() => _tab = idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: _tab == idx ? AppColors.green400 : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: _tab == idx ? FontWeight.w700 : FontWeight.w500,
            color: _tab == idx ? Colors.white : AppColors.muted,
          ),
        ),
      ),
    ),
  );

  Widget _body() {
    switch (_tab) {
      case 0:
        return _signalTab();
      case 1:
        return _chatTab();
      case 2:
        return _ragTab();
      default:
        return const SizedBox();
    }
  }

  Widget _signalTab() => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Agriculture Disease Detection Section
        if (_selectedCat == 4) // Agriculture category
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.green200, width: 1.5),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppColors.green400, AppColors.green600]),
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: AppColors.green400.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 4))],
                        ),
                        child: const Icon(Icons.agriculture, color: Colors.white, size: 28),
                      ),
                      const SizedBox(height: 12),
                      Text('Date Palm Disease Detection', style: GoogleFonts.syne(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                      const SizedBox(height: 8),
                      Text('Analyze palm tree health using AI', style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.muted), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      // Image picker buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _pickImage(ImageSource.camera),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.green50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.green200),
                                ),
                                child: Column(
                                  children: [
                                    const Icon(Icons.camera_alt, color: AppColors.green600, size: 20),
                                    const SizedBox(height: 4),
                                    Text('Camera', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.green600)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _pickImage(ImageSource.gallery),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.green50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.green200),
                                ),
                                child: Column(
                                  children: [
                                    const Icon(Icons.image, color: AppColors.green600, size: 20),
                                    const SizedBox(height: 4),
                                    Text('Gallery', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.green600)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Image preview
                      if (_selectedImage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(_selectedImage!, height: 200, fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: _isAnalyzing ? null : _analyzeDisease,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              gradient: _isAnalyzing ? LinearGradient(colors: [AppColors.green400.withValues(alpha: 0.5), AppColors.green600.withValues(alpha: 0.5)]) : const LinearGradient(colors: [AppColors.green400, AppColors.green600]),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_isAnalyzing) ...[
                                  const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))),
                                  const SizedBox(width: 8),
                                ],
                                Text(_isAnalyzing ? 'Analyzing...' : 'Analyze Disease', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                      ],
                      // Disease results
                      if (_diseaseResult != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.green50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.green200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Analysis Results', style: GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.green600)),
                              const SizedBox(height: 12),
                              // Disease name
                              Text(
                                _diseaseResult!['disease'] ?? 'Unknown',
                                style: GoogleFonts.syne(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.green700),
                              ),
                              const SizedBox(height: 8),
                              // Confidence and severity
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Confidence: ${(_diseaseResult!['confidence_pct'] ?? 0).toStringAsFixed(1)}%',
                                    style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: (_diseaseResult!['severity'] == 'High') ? Colors.red.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Severity: ${_diseaseResult!['severity'] ?? 'Unknown'}',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: (_diseaseResult!['severity'] == 'High') ? Colors.red.shade700 : Colors.orange.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Recommendations
                              if (_diseaseResult!['recommendations'] is List && (_diseaseResult!['recommendations'] as List).isNotEmpty) ...[
                                Text('Recommendations:', style: GoogleFonts.syne(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.green600)),
                                const SizedBox(height: 8),
                                ...((_diseaseResult!['recommendations'] as List).cast<String>()).map((rec) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('• ', style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.green600)),
                                      Expanded(
                                        child: Text(
                                          rec,
                                          style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textPrimary),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                              ],
                              const SizedBox(height: 12),
                              // All class probabilities
                              if (_diseaseResult!['all_classes'] is List && (_diseaseResult!['all_classes'] as List).isNotEmpty) ...
                                [

                                Text('All Classifications:', style: GoogleFonts.syne(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.muted)),
                                const SizedBox(height: 8),
                                ...((_diseaseResult!['all_classes'] as List).cast<Map<String, dynamic>>()).map((cls) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(cls['name'] ?? 'Unknown', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textPrimary)),
                                      Text(
                                        '${((cls['probability'] as num? ?? 0) * 100).toStringAsFixed(1)}%',
                                        style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.green600),
                                      ),
                                    ],
                                  ),
                                )),
                              ],
                            ],
                          ),
                        ),
                        // Segmented image display
                        if (_segmentedImage != null) ...[
                          const SizedBox(height: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Disease Segmentation Map', style: GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.green600)),
                              const SizedBox(height: 12),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.memory(_segmentedImage!, height: 200, fit: BoxFit.cover),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                      // Error message
                      if (_analysisError != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                          ),
                          child: Text(_analysisError!, style: GoogleFonts.dmSans(fontSize: 12, color: Colors.red.shade700)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
          )
        else
          // Standard report issue section
          GestureDetector(
            child: Container(
              margin: const EdgeInsets.all(14),
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.green200, width: 1.5),
              ),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppColors.green400, AppColors.green600]),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: AppColors.green400.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 4))],
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 26),
                  ),
                  const SizedBox(height: 10),
                  Text('Report an Issue', style: GoogleFonts.syne(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text('Take a photo or describe a problem in Gabès', style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.muted), textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(
              _cats.length,
              (i) => GestureDetector(
                onTap: () => setState(() => _selectedCat = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _selectedCat == i ? AppColors.green400.withValues(alpha: 0.06) : Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: _selectedCat == i ? AppColors.green400.withValues(alpha: 0.4) : AppColors.border, width: 1.5),
                  ),
                  child: Text(_cats[i], style: GoogleFonts.dmSans(fontSize: 12, fontWeight: _selectedCat == i ? FontWeight.w700 : FontWeight.w500, color: _selectedCat == i ? AppColors.green600 : AppColors.muted)),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.borderStrong, width: 1.5)),
          child: TextField(
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Describe the issue in detail…',
              hintStyle: GoogleFonts.dmSans(color: AppColors.lightText, fontSize: 13),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.green400, AppColors.green600]), borderRadius: BorderRadius.circular(14)),
            child: Text('Submit Report', textAlign: TextAlign.center, style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ),
        const SizedBox(height: 24),
      ],
    ),
  );

  Widget _chatTab() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      _chatBubble('FT', 'Fatma T.', 'The industrial zone smell is unbearable today.', false, '10:24'),
      _chatBubble('', '', 'I reported it already. Waiting for municipality response.', true, '10:26'),
      _chatBubble('KM', 'Khaled M.', 'Same here in Zone Sud. They need to act fast!', false, '10:28'),
      _chatBubble('', '', 'Let\'s coordinate — I\'ll contact the environmental office.', true, '10:31'),
      _chatBubble('NB', 'Nadia B.', 'Thank you! Adding photos to the signal thread.', false, '10:33'),
    ],
  );

  Widget _chatBubble(String initials, String name, String msg, bool isMe, String time) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(color: AppColors.green50, shape: BoxShape.circle),
              child: Center(child: Text(initials, style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.green600))),
            ),
            const SizedBox(width: 7),
          ],
          Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isMe) Padding(padding: const EdgeInsets.only(left: 2, bottom: 3), child: Text(name, style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.green500))),
              Container(
                constraints: const BoxConstraints(maxWidth: 220),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isMe ? const LinearGradient(colors: [AppColors.green400, AppColors.green600]) : null,
                  color: isMe ? null : Colors.white,
                  borderRadius: BorderRadius.only(topLeft: const Radius.circular(16), topRight: const Radius.circular(16), bottomLeft: Radius.circular(isMe ? 16 : 4), bottomRight: Radius.circular(isMe ? 4 : 16)),
                  border: isMe ? null : Border.all(color: AppColors.border),
                ),
                child: Text(msg, style: GoogleFonts.dmSans(fontSize: 13, color: isMe ? Colors.white : AppColors.textPrimary, height: 1.5)),
              ),
              const SizedBox(height: 3),
              Text(time, style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.lightText)),
            ],
          ),
        ],
      ),
    );

  Widget _ragTab() => Column(
    children: [
      Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Project', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.muted, letterSpacing: 0.5)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
              child: DropdownButton<String>(
                value: _selectedProject,
                isExpanded: true,
                underline: const SizedBox(),
                style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textPrimary),
                items: [
                  DropdownMenuItem(value: null, child: Text('All Gabes projects', style: GoogleFonts.dmSans(fontSize: 13))),
                  ..._projects.map((project) => DropdownMenuItem(value: project, child: Text(project, style: GoogleFonts.dmSans(fontSize: 13)))),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedProject = value;
                    _ragMessages.clear();
                    _currentSources = [];
                    _showSources = false;
                  });
                },
              ),
            ),
          ],
        ),
      ),
      if (_ragMessages.isEmpty)
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.green400, AppColors.green600]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Explore Investment Opportunities',
                        style: GoogleFonts.syne(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ask grounded questions about ${_selectedProject ?? "Gabes"} projects. Get instant insights backed by real documents.',
                        style: GoogleFonts.dmSans(fontSize: 12, color: Colors.white.withValues(alpha: 0.9), height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text('Quick Research Questions', style: GoogleFonts.syne(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                ...[
                  'What is the objective of this project?',
                  'What budget and dates are mentioned?',
                  'Who are the stakeholders and beneficiaries?',
                  'What execution actions are described?',
                  'What is the expected impact?',
                ].map((question) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () {
                      _ragInputCtrl.text = question;
                      _sendRAGMessage();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.green50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.green100),
                      ),
                      child: Text(
                        question,
                        style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.green700, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                )),
              ],
            ),
          ),
        )
      else
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: _ragMessages.length + (_showSources ? 1 : 0),
            itemBuilder: (context, idx) {
              if (_showSources && idx == _ragMessages.length) {
                return _sourcesWidget();
              }
              final msg = _ragMessages[idx];
              return _ragBubble(msg);
            },
          ),
        ),
    ],
  );

  Widget _ragBubble(RAGMessage msg) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      mainAxisAlignment: msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!msg.isUser) Container(width: 28, height: 28, decoration: const BoxDecoration(color: AppColors.green50, shape: BoxShape.circle), child: const Center(child: Text('🤖', style: TextStyle(fontSize: 14)))),
        if (!msg.isUser) const SizedBox(width: 7),
        Column(
          crossAxisAlignment: msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!msg.isUser) Padding(padding: const EdgeInsets.only(left: 2, bottom: 3), child: Text('Project Assistant', style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.green500))),
            Container(
              constraints: const BoxConstraints(maxWidth: 240),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: msg.isUser ? const LinearGradient(colors: [AppColors.green400, AppColors.green600]) : null,
                color: msg.isUser ? null : Colors.white,
                borderRadius: BorderRadius.only(topLeft: const Radius.circular(16), topRight: const Radius.circular(16), bottomLeft: Radius.circular(msg.isUser ? 16 : 4), bottomRight: Radius.circular(msg.isUser ? 4 : 16)),
                border: msg.isUser ? null : Border.all(color: AppColors.border),
              ),
              child: Text(msg.text, style: GoogleFonts.dmSans(fontSize: 13, color: msg.isUser ? Colors.white : AppColors.textPrimary, height: 1.5)),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _sourcesWidget() => Container(
    margin: const EdgeInsets.only(top: 16, bottom: 16),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: AppColors.green50, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.green100)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sources', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.green600, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        ..._currentSources.asMap().entries.map((e) {
          final idx = e.key;
          final source = e.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${source.project} • ${source.filename}', style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.green600)),
                            const SizedBox(height: 2),
                            Text('Page ${source.page} • Chunk ${source.chunkIndex} • Score: ${(source.score * 100).toStringAsFixed(0)}%', style: GoogleFonts.dmSans(fontSize: 9, color: AppColors.muted)),
                          ],
                        ),
                      ),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), decoration: BoxDecoration(color: AppColors.green100, borderRadius: BorderRadius.circular(4)), child: Text('${source.score.toStringAsFixed(2)}', style: GoogleFonts.dmSans(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.green600))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(source.snippet, style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textPrimary, height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    ),
  );

  Widget _chatInputBar() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.border))),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: _chatCtrl,
            decoration: InputDecoration(
              hintText: 'Message the community…',
              hintStyle: GoogleFonts.dmSans(color: AppColors.lightText, fontSize: 13),
              filled: true,
              fillColor: AppColors.bg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: const BorderSide(color: AppColors.green400)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.green400, AppColors.green600]),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: AppColors.green400.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: const Icon(Icons.send_rounded, color: Colors.white, size: 16),
        ),
      ],
    ),
  );

  Widget _ragInputBar() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.border))),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: _ragInputCtrl,
            enabled: !_ragLoading,
            decoration: InputDecoration(
              hintText: 'Ask about projects…',
              hintStyle: GoogleFonts.dmSans(color: AppColors.lightText, fontSize: 13),
              filled: true,
              fillColor: AppColors.bg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: const BorderSide(color: AppColors.green400)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _ragLoading ? null : _sendRAGMessage,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.green400, AppColors.green600]),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: AppColors.green400.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: _ragLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                : const Icon(Icons.send_rounded, color: Colors.white, size: 16),
          ),
        ),
      ],
    ),
  );
}

class RAGMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  RAGMessage({required this.text, required this.isUser, required this.timestamp});
}