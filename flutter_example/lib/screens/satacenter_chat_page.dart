import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/chat_models.dart';
import '../services/satacenter_api.dart';

class SatacenterChatPage extends StatefulWidget {
  const SatacenterChatPage({
    super.key,
    required this.api,
  });

  final SatacenterApi api;

  @override
  State<SatacenterChatPage> createState() => _SatacenterChatPageState();
}

class _SatacenterChatPageState extends State<SatacenterChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ProjectSummary> _projects = const [];
  List<ChatTurn> _messages = const [
    ChatTurn(
      role: 'assistant',
      content:
          'Welcome to Satacenter Gabes. Select a project and ask about goals, feasibility, execution steps, stakeholders, or risks.',
    ),
  ];
  String? _selectedProject;
  bool _loadingProjects = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    setState(() {
      _loadingProjects = true;
      _error = null;
    });

    try {
      final projects = await widget.api.fetchProjects();
      if (!mounted) {
        return;
      }
      setState(() {
        _projects = projects;
        _loadingProjects = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingProjects = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) {
      return;
    }

    final nextMessages = List<ChatTurn>.from(_messages)
      ..add(ChatTurn(role: 'user', content: text));

    setState(() {
      _sending = true;
      _error = null;
      _messages = nextMessages;
      _messageController.clear();
    });
    _jumpToBottom();

    try {
      final response = await widget.api.sendMessage(
        message: text,
        project: _selectedProject,
        history: nextMessages
            .where((message) => message.role == 'user' || message.role == 'assistant')
            .toList(),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _messages = List<ChatTurn>.from(_messages)
          ..add(
            ChatTurn(
              role: 'assistant',
              content: response.answer.isNotEmpty
                  ? response.answer
                  : 'I could not find a grounded answer in the indexed sources.',
              sources: response.sources,
            ),
          );
        _sending = false;
        if ((response.project ?? '').isNotEmpty) {
          _selectedProject = response.project;
        }
        if (response.llmError != null && response.llmError!.isNotEmpty) {
          _error = response.llmError;
        }
      });
      _jumpToBottom();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _sending = false;
        _error = error.toString();
      });
    }
  }

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = GoogleFonts.spaceGrotesk(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: const Color(0xFFF6F0E8),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0E1B1A),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0E1B1A),
              Color(0xFF13332F),
              Color(0xFF1D4C45),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Satacenter Gabes', style: titleStyle),
                    const SizedBox(height: 8),
                    Text(
                      'A project decision assistant powered by RAG, built for clean jury demos and easy Flutter integration.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        height: 1.5,
                        color: const Color(0xFFD7E3DF),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _ProjectSelector(
                      projects: _projects,
                      selectedProject: _selectedProject,
                      loading: _loadingProjects,
                      onChanged: (value) {
                        setState(() {
                          _selectedProject = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F5EF),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    children: [
                      if (_error != null && _error!.isNotEmpty)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE7D6),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _error!,
                            style: GoogleFonts.inter(
                              color: const Color(0xFF7A3713),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length + (_sending ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (_sending && index == _messages.length) {
                              return const _TypingCard();
                            }
                            return _MessageCard(message: _messages[index]);
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                minLines: 1,
                                maxLines: 5,
                                textInputAction: TextInputAction.send,
                                onSubmitted: (_) => _sendMessage(),
                                decoration: InputDecoration(
                                  hintText: 'Ask about execution, risks, budget, impact...',
                                  hintStyle: GoogleFonts.inter(),
                                  filled: true,
                                  fillColor: const Color(0xFFEDE6D9),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(18),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            FilledButton(
                              onPressed: _sendMessage,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF0D6B5C),
                                minimumSize: const Size(58, 58),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: const Icon(Icons.arrow_upward_rounded),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectSelector extends StatelessWidget {
  const _ProjectSelector({
    required this.projects,
    required this.selectedProject,
    required this.loading,
    required this.onChanged,
  });

  final List<ProjectSummary> projects;
  final String? selectedProject;
  final bool loading;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const LinearProgressIndicator(
        minHeight: 3,
        backgroundColor: Color(0x3349A08D),
        color: Color(0xFFF2B260),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0x1AF8F5EF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x26F8F5EF)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          isExpanded: true,
          value: selectedProject,
          dropdownColor: const Color(0xFF173530),
          hint: Text(
            'All Gabes projects',
            style: GoogleFonts.inter(color: const Color(0xFFF8F5EF)),
          ),
          iconEnabledColor: const Color(0xFFF8F5EF),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text(
                'All Gabes projects',
                style: GoogleFonts.inter(color: const Color(0xFFF8F5EF)),
              ),
            ),
            ...projects.map(
              (project) => DropdownMenuItem<String?>(
                value: project.project,
                child: Text(
                  '${project.project} - ${project.documentCount} docs',
                  style: GoogleFonts.inter(color: const Color(0xFFF8F5EF)),
                ),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message});

  final ChatTurn message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final bubbleColor = isUser ? const Color(0xFF0D6B5C) : const Color(0xFFEDE6D9);
    final textColor = isUser ? Colors.white : const Color(0xFF173530);
    final alignment = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 680),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Text(
              message.content,
              style: GoogleFonts.inter(
                color: textColor,
                fontSize: 15,
                height: 1.6,
              ),
            ),
          ),
          if (!isUser && message.sources.isNotEmpty)
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: message.sources.take(3).map((source) {
                final pageLabel =
                    source.page == null ? 'Document section' : 'Page ${source.page}';
                return Container(
                  width: 220,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFD9D0C1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        source.project,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF173530),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$pageLabel - score ${source.score.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF6E746D),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        source.snippet,
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          height: 1.5,
                          color: const Color(0xFF24312F),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _TypingCard extends StatelessWidget {
  const _TypingCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFEDE6D9),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              _PulseDot(delay: 0),
              SizedBox(width: 6),
              _PulseDot(delay: 120),
              SizedBox(width: 6),
              _PulseDot(delay: 240),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.delay});

  final int delay;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 1).animate(_controller),
      child: const CircleAvatar(
        radius: 4,
        backgroundColor: Color(0xFF0D6B5C),
      ),
    );
  }
}
