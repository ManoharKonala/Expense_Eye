import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import '../app_language.dart';

class FinanceAdviserChatScreen extends StatefulWidget {
  const FinanceAdviserChatScreen({super.key});

  @override
  State<FinanceAdviserChatScreen> createState() =>
      _FinanceAdviserChatScreenState();
}

class _FinanceAdviserChatScreenState extends State<FinanceAdviserChatScreen> {
  static String get _groqApiKey => dotenv.env['GROQ_API_KEY'] ?? '';
  static const String _groqModel = 'llama-3.3-70b-versatile';
  static String get _speechmaticsApiKey =>
      dotenv.env['SPEECHMATICS_API_KEY'] ?? '';
  static final Uri _groqChatUri = Uri.parse(
    'https://api.groq.com/openai/v1/chat/completions',
  );
  static final Uri _speechmaticsJobsUri = Uri.parse(
    'https://asr.api.speechmatics.com/v2/jobs/',
  );

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final List<_ChatMessage> _messages = _FinanceChatSession.messages;

  bool _isSending = false;
  bool _isRecording = false;
  bool _isTranscribingVoice = false;
  String? _recordingPath;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  String _decodeResponse(http.Response response) {
    return utf8.decode(response.bodyBytes);
  }

  bool get _hasRequiredKeys =>
      _groqApiKey.isNotEmpty && _speechmaticsApiKey.isNotEmpty;

  String _speechmaticsLanguageCode() {
    switch (AppLanguageController.language.value) {
      case AppLanguage.hindi:
        return 'hi';
      case AppLanguage.marathi:
        return 'mr';
      case AppLanguage.english:
        return 'en';
    }
  }

  Future<void> _toggleVoiceInput() async {
    if (_isTranscribingVoice || _isSending) return;

    if (!_hasRequiredKeys) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Missing API keys. Add them to your local .env file.'),
        ),
      );
      return;
    }

    if (_isRecording) {
      await _stopVoiceRecordingAndSend();
      return;
    }

    final permission = await Permission.microphone.request();
    final hasRecorderPermission = await _audioRecorder.hasPermission();

    if (!permission.isGranted && !hasRecorderPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.current.t('micPermissionRequired'))),
      );
      return;
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final path =
          '${tempDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 16000,
          numChannels: 1,
          bitRate: 64000,
        ),
        path: path,
      );

      setState(() {
        _recordingPath = path;
        _isRecording = true;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.current.t('voiceNotSupported'))),
      );
    }
  }

  Future<void> _stopVoiceRecordingAndSend() async {
    setState(() {
      _isRecording = false;
      _isTranscribingVoice = true;
    });

    try {
      final path = await _audioRecorder.stop() ?? _recordingPath;
      if (path == null) {
        throw Exception('No audio file');
      }

      await Future<void>.delayed(const Duration(milliseconds: 350));

      final audioFile = File(path);
      if (!await audioFile.exists()) {
        throw _VoiceInputException(AppStrings.current.t('voiceEmpty'));
      }

      final fileSize = await audioFile.length();
      if (fileSize < 128) {
        throw _VoiceInputException(AppStrings.current.t('voiceEmpty'));
      }

      final transcript = await _transcribeWithSpeechmatics(path);
      if (!mounted) return;

      if (transcript.isEmpty) {
        throw Exception('Empty transcript');
      }

      _messageController.text = transcript;
      await _sendMessage();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is _VoiceInputException
                ? error.message
                : AppStrings.current.t('voiceFailed'),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isTranscribingVoice = false;
          _recordingPath = null;
        });
      }
    }
  }

  Future<String> _transcribeWithSpeechmatics(String filePath) async {
    final request = http.MultipartRequest('POST', _speechmaticsJobsUri)
      ..headers['Authorization'] = 'Bearer $_speechmaticsApiKey'
      ..fields['config'] = jsonEncode({
        'type': 'transcription',
        'transcription_config': {'language': _speechmaticsLanguageCode()},
      })
      ..files.add(await http.MultipartFile.fromPath('data_file', filePath));

    final createResponse = await request.send();
    final createBody = await createResponse.stream.bytesToString();
    if (createResponse.statusCode < 200 || createResponse.statusCode >= 300) {
      throw _VoiceInputException(
        'Speechmatics create job failed: ${createResponse.statusCode} $createBody',
      );
    }

    final createJson = jsonDecode(createBody) as Map<String, dynamic>;
    final jobId = createJson['id'] as String?;
    if (jobId == null || jobId.isEmpty) {
      throw _VoiceInputException('Speechmatics job id missing');
    }

    for (var attempt = 0; attempt < 20; attempt++) {
      await Future<void>.delayed(const Duration(seconds: 1));

      final statusResponse = await http.get(
        Uri.parse('https://asr.api.speechmatics.com/v2/jobs/$jobId'),
        headers: {'Authorization': 'Bearer $_speechmaticsApiKey'},
      );
      final statusBody = _decodeResponse(statusResponse);
      if (statusResponse.statusCode < 200 || statusResponse.statusCode >= 300) {
        throw _VoiceInputException(
          'Speechmatics job status failed: ${statusResponse.statusCode} $statusBody',
        );
      }

      final statusJson = jsonDecode(statusBody) as Map<String, dynamic>;
      final job = statusJson['job'] as Map<String, dynamic>? ?? const {};
      final status = job['status'] as String? ?? '';

      if (status == 'done') {
        final transcriptResponse = await http.get(
          Uri.parse(
            'https://asr.api.speechmatics.com/v2/jobs/$jobId/transcript?format=txt',
          ),
          headers: {'Authorization': 'Bearer $_speechmaticsApiKey'},
        );
        if (transcriptResponse.statusCode < 200 ||
            transcriptResponse.statusCode >= 300) {
          throw _VoiceInputException(
            'Speechmatics transcript failed: ${transcriptResponse.statusCode}',
          );
        }
        final transcript = _decodeResponse(transcriptResponse).trim();
        if (transcript.isEmpty) {
          throw _VoiceInputException(AppStrings.current.t('voiceEmpty'));
        }
        return transcript;
      }

      if (status == 'rejected' || status == 'deleted' || status == 'expired') {
        final reason =
            job['error'] ??
            job['reason'] ??
            statusJson['error'] ??
            'Speechmatics job failed with status $status';
        throw _VoiceInputException(reason.toString());
      }
    }

    throw _VoiceInputException('Speechmatics job timeout');
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    if (!_hasRequiredKeys) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Missing API keys. Add them to your local .env file.'),
        ),
      );
      return;
    }

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _messageController.clear();
    });
    _scrollToBottom();

    setState(() => _isSending = true);

    try {
      final response = await http.post(
        _groqChatUri,
        headers: {
          'Authorization': 'Bearer $_groqApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _groqModel,
          'temperature': 0.4,
          'max_completion_tokens': 220,
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are Financer Adviser, a helpful financial education chatbot for an expense tracker app. ${AppStrings.current.languageInstruction} Give only finance, budgeting, savings, debt, tax planning, insurance, investment planning, SIP, and mutual fund advice. Do not answer non-finance questions. Be advisory and useful, not overly refusing. Keep advice practical for Indian users. Keep every answer short, clean, and easy to scan: maximum 4 bullet points or 70 words. Use plain language. No long paragraphs. No mathematical calculations, formulas, equations, or step-by-step arithmetic. If numbers are needed, calculate silently and show only the final rounded answer. For stock questions, do not guarantee buy calls; give general guidance such as index funds, large-cap/blue-chip focus, risk level, time horizon, or small allocation ideas. For mutual funds, suggest suitable categories like index, large-cap, flexi-cap, debt/liquid, or SIP. End with one short risk note only when investing is involved.',
            },
            ..._messages
                .take(_messages.length - 1)
                .map(
                  (message) => {
                    'role': message.isUser ? 'user' : 'assistant',
                    'content': message.text,
                  },
                ),
            {'role': 'user', 'content': text},
          ],
        }),
      );

      if (!mounted) return;

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Groq request failed with ${response.statusCode}');
      }

      final body =
          jsonDecode(_decodeResponse(response)) as Map<String, dynamic>;
      final choices = body['choices'] as List<dynamic>? ?? [];
      final message = choices.isNotEmpty
          ? choices.first['message'] as Map<String, dynamic>?
          : null;
      final content = message?['content'] as String?;

      setState(() {
        _messages.add(
          _ChatMessage(
            text: content?.trim().isNotEmpty == true
                ? content!.trim()
                : AppStrings.current.t('chatEmpty'),
            isUser: false,
          ),
        );
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          _ChatMessage(text: AppStrings.current.t('chatError'), isUser: false),
        );
      });
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: AppLanguageController.language,
      builder: (context, language, child) {
        final strings = AppStrings.current;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F6FA),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios,
                color: Colors.black,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              strings.t('financerAdviser'),
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                tooltip: strings.t('newSession'),
                icon: const Icon(Icons.refresh, color: Colors.black54),
                onPressed: () {
                  setState(_FinanceChatSession.reset);
                  _scrollToBottom();
                },
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                strings.t('financeGuidance'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                strings.t('financeGuidanceSub'),
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 12,
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: _messages.length + (_isSending ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isSending && index == _messages.length) {
                        return const _TypingBubble();
                      }
                      return _MessageBubble(message: _messages[index]);
                    },
                  ),
                ),
                _MessageComposer(
                  controller: _messageController,
                  isSending: _isSending,
                  isRecording: _isRecording,
                  isTranscribingVoice: _isTranscribingVoice,
                  onSend: _sendMessage,
                  onToggleVoiceInput: _toggleVoiceInput,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({
    required this.controller,
    required this.isSending,
    required this.isRecording,
    required this.isTranscribingVoice,
    required this.onSend,
    required this.onToggleVoiceInput,
  });

  final TextEditingController controller;
  final bool isSending;
  final bool isRecording;
  final bool isTranscribingVoice;
  final VoidCallback onSend;
  final VoidCallback onToggleVoiceInput;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: isTranscribingVoice
                    ? AppStrings.current.t('voiceProcessing')
                    : isRecording
                    ? AppStrings.current.t('voiceListening')
                    : AppStrings.current.t('chatHint'),
                filled: true,
                fillColor: const Color(0xFFF5F6FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 46,
            height: 46,
            child: ElevatedButton(
              onPressed: isSending || isTranscribingVoice
                  ? null
                  : onToggleVoiceInput,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: isRecording ? Colors.redAccent : Colors.white,
                foregroundColor: isRecording ? Colors.white : Colors.deepPurple,
                elevation: 0,
                side: BorderSide(
                  color: isRecording
                      ? Colors.redAccent
                      : Colors.deepPurple.withValues(alpha: 0.2),
                ),
                shape: const CircleBorder(),
              ),
              child: isTranscribingVoice
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      isRecording ? Icons.stop_rounded : Icons.mic_none_rounded,
                      size: 20,
                    ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 48,
            height: 48,
            child: ElevatedButton(
              onPressed: isSending ? null : onSend,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: const CircleBorder(),
              ),
              child: isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final alignment = message.isUser
        ? Alignment.centerRight
        : Alignment.centerLeft;
    final bubbleColor = message.isUser ? Colors.deepPurple : Colors.white;
    final textColor = message.isUser ? Colors.white : Colors.black87;

    return Align(
      alignment: alignment,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.74,
        ),
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(message.isUser ? 18 : 4),
            bottomRight: Radius.circular(message.isUser ? 4 : 18),
          ),
          boxShadow: message.isUser
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Text(
          message.text,
          style: TextStyle(color: textColor, fontSize: 13, height: 1.28),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          AppStrings.current.t('typing'),
          style: const TextStyle(color: Colors.black45, fontSize: 13),
        ),
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({required this.text, required this.isUser});

  final String text;
  final bool isUser;
}

class _FinanceChatSession {
  static final List<_ChatMessage> messages = [_welcomeMessage()];

  static _ChatMessage _welcomeMessage() {
    return _ChatMessage(
      text: AppStrings.current.t('chatWelcome'),
      isUser: false,
    );
  }

  static void reset() {
    messages
      ..clear()
      ..add(_welcomeMessage());
  }
}

class _VoiceInputException implements Exception {
  const _VoiceInputException(this.message);

  final String message;
}
