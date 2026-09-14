import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../models/chat_attachment.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';
import '../providers/weather_provider.dart';
import '../utils/theme.dart';
import '../widgets/glass_container.dart';
import '../widgets/location_search_modal.dart';
import '../widgets/persona_modal.dart';

class AdvisorChatScreen extends StatefulWidget {
  const AdvisorChatScreen({super.key});

  @override
  State<AdvisorChatScreen> createState() => _AdvisorChatScreenState();
}

class _AdvisorChatScreenState extends State<AdvisorChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  final List<ChatAttachment> _pendingAttachments = [];

  List<String> _getQuickPrompts(bool isNightOrZeroUv) {
    if (isNightOrZeroUv) {
      return [
        'What is the overnight forecast & temperature?',
        'Is it safe for an evening workout or walk?',
        'Should I irrigate crops or hold for rain?',
        'How is road visibility for night commute?',
      ];
    }
    return [
      'What is the best running window today?',
      'What are the UV & skin safety recommendations?',
      'Should I irrigate crops or hold for rain?',
      'How is road visibility for commute?',
    ];
  }

  void _sendMessage([String? customText]) {
    final text = (customText ?? _textController.text).trim();
    if (text.isEmpty && _pendingAttachments.isEmpty) return;

    final attachmentsToSend = List<ChatAttachment>.from(_pendingAttachments);
    _textController.clear();
    setState(() {
      _pendingAttachments.clear();
    });

    context.read<WeatherProvider>().sendChatMessage(
      text,
      attachments: attachmentsToSend.isNotEmpty ? attachmentsToSend : null,
    );

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 220,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final base64Str = base64Encode(bytes);
        final extension = picked.name.split('.').last.toLowerCase();
        final mimeType = extension == 'png'
            ? 'image/png'
            : (extension == 'webp' ? 'image/webp' : 'image/jpeg');

        setState(() {
          _pendingAttachments.add(ChatAttachment(
            id: 'att_${DateTime.now().millisecondsSinceEpoch}',
            name: picked.name,
            mimeType: mimeType,
            base64Data: base64Str,
            sizeBytes: bytes.length,
            isImage: true,
          ));
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not attach image: $e'),
          backgroundColor: AppColors.alertRed,
        ),
      );
    }
  }

  Future<void> _pickDocument() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt', 'csv', 'doc', 'docx'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final bytes = file.bytes;
        if (bytes != null) {
          final base64Str = base64Encode(bytes);
          final ext = file.extension?.toLowerCase() ?? '';
          String mime = 'application/octet-stream';
          if (ext == 'pdf') {
            mime = 'application/pdf';
          } else if (ext == 'txt') {
            mime = 'text/plain';
          } else if (ext == 'csv') {
            mime = 'text/csv';
          } else if (ext == 'doc' || ext == 'docx') {
            mime = 'application/msword';
          }

          setState(() {
            _pendingAttachments.add(ChatAttachment(
              id: 'att_${DateTime.now().millisecondsSinceEpoch}',
              name: file.name,
              mimeType: mime,
              base64Data: base64Str,
              sizeBytes: bytes.length,
              isImage: false,
            ));
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not attach document: $e'),
          backgroundColor: AppColors.alertRed,
        ),
      );
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withOpacity(0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppColors.glassBorderBright),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add Attachment',
                    style: AppTypography.headlineMd.copyWith(fontSize: 18),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.onSurfaceVariant),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAttachOptionItem(
                    icon: Icons.camera_alt_rounded,
                    label: 'Take Photo',
                    color: AppColors.primaryContainer,
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  _buildAttachOptionItem(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery Image',
                    color: AppColors.fitnessViolet,
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                  _buildAttachOptionItem(
                    icon: Icons.picture_as_pdf_rounded,
                    label: 'Document / PDF',
                    color: AppColors.electricCyan,
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickDocument();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachOptionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.4)),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTypography.bodySm.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChatSessionsSheet(BuildContext context, WeatherProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ChatSessionsModal(provider: provider),
    );
  }

  void _showImagePreviewDialog(ChatAttachment attachment) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                color: const Color(0xFF0F172A),
                child: Image.memory(
                  attachment.bytes,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.6),
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (context, provider, _) {
        final int currentHour = DateTime.now().hour;
        final bool isNight = currentHour < 6 || currentHour >= 19;
        final bool isNightOrZeroUv = isNight || (provider.telemetry?.uvIndex ?? 0) <= 0.5;
        final quickPrompts = _getQuickPrompts(isNightOrZeroUv);
        final activeSession = provider.activeSession;

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.forum_outlined, color: AppColors.primary, size: 22),
              tooltip: 'Recent Conversations',
              onPressed: () => _showChatSessionsSheet(context, provider),
            ),
            title: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const LocationSearchModal(),
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 18),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      provider.cityName,
                      style: AppTypography.titleMd.copyWith(fontSize: 15),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.onSurfaceVariant, size: 16),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_note_rounded, color: AppColors.electricCyan, size: 24),
                tooltip: 'New Chat',
                onPressed: () {
                  provider.createNewChatSession();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Started New Conversation'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              IconButton(
                icon: Icon(provider.activePersona.icon, color: provider.activePersona.accentColor, size: 22),
                tooltip: 'Persona Settings',
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const PersonaModal(),
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Subheader Card with Active Session Title & Persona Pill
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: GlassContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  borderRadius: 20.0,
                  fillColor: AppColors.primaryContainer.withOpacity(0.08),
                  borderColor: AppColors.primaryContainer.withOpacity(0.2),
                  child: Row(
                    children: [
                      // AI Avatar Icon with Glow
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [AppColors.primaryContainer, AppColors.fitnessViolet],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryContainer.withOpacity(0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Session Title and Persona Pill
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AdvisorAI',
                              style: AppTypography.headlineMd.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              activeSession.title,
                              style: AppTypography.bodySm.copyWith(
                                fontSize: 11,
                                color: AppColors.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          provider.activePersona.shortTitle,
                          style: AppTypography.labelCaps.copyWith(
                            fontSize: 10,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Quick Prompt Suggestion Chips (Horizontal Carousel)
              Container(
                height: 44,
                margin: const EdgeInsets.only(top: 6.0),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  scrollDirection: Axis.horizontal,
                  itemCount: quickPrompts.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final prompt = quickPrompts[index];
                    return ActionChip(
                      backgroundColor: AppColors.surface.withOpacity(0.65),
                      side: BorderSide(
                        color: AppColors.primary.withOpacity(0.2),
                        width: 1,
                      ),
                      elevation: 0,
                      pressElevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      label: Text(
                        prompt,
                        style: AppTypography.bodySm.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.onSurface,
                        ),
                      ),
                      onPressed: () => _sendMessage(prompt),
                    );
                  },
                ),
              ),

              // Chat Message Stream List
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  itemCount: provider.chatMessages.length,
                  itemBuilder: (context, index) {
                    final msg = provider.chatMessages[index];
                    return TweenAnimationBuilder<double>(
                      key: ValueKey(msg.id),
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      builder: (context, animValue, child) {
                        return Opacity(
                          opacity: animValue,
                          child: Transform.translate(
                            offset: Offset(0, 12 * (1 - animValue)),
                            child: child,
                          ),
                        );
                      },
                      child: _buildMessageBubble(msg),
                    );
                  },
                ),
              ),

              // Animated Chat Loading Bubble with Pulsing Dots
              if (provider.isChatLoading)
                const Padding(
                  padding: EdgeInsets.only(left: 16.0, right: 48.0, bottom: 8.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _AnimatedTypingIndicator(),
                  ),
                ),

              // Bottom Input Bar with Attachment Preview Tray (Snug fit above bottom nav when closed, and snug 8px on top of keyboard when open)
              Container(
                padding: EdgeInsets.fromLTRB(
                  16,
                  4,
                  16,
                  MediaQuery.of(context).viewInsets.bottom > 0 ? 8.0 : 88.0,
                ),
                child: GlassContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  borderRadius: 26,
                  borderColor: AppColors.glassBorderBright,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Pending Attachments Preview Tray
                      if (_pendingAttachments.isNotEmpty)
                        Container(
                          height: 60,
                          padding: const EdgeInsets.only(left: 8, right: 8, top: 6, bottom: 2),
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _pendingAttachments.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final att = _pendingAttachments[index];
                              return Stack(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface.withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AppColors.glassBorder),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (att.isImage)
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(6),
                                            child: Image.memory(
                                              att.bytes,
                                              width: 42,
                                              height: 42,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        else
                                          Container(
                                            width: 42,
                                            height: 42,
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Icon(
                                              Icons.description_rounded,
                                              color: AppColors.primary,
                                              size: 22,
                                            ),
                                          ),
                                        const SizedBox(width: 8),
                                        ConstrainedBox(
                                          constraints: const BoxConstraints(maxWidth: 120),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                att.fileName,
                                                style: AppTypography.bodySm.copyWith(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                att.formattedSize,
                                                style: AppTypography.bodySm.copyWith(
                                                  fontSize: 9,
                                                  color: AppColors.onSurfaceVariant,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _pendingAttachments.removeAt(index);
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: AppColors.alertRed,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close_rounded,
                                          color: Colors.white,
                                          size: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),

                      // Input row with attachment button, text field, and send button
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.attach_file_rounded, color: AppColors.electricCyan, size: 22),
                            tooltip: 'Add Attachment',
                            onPressed: _showAttachmentOptions,
                          ),
                          Expanded(
                            child: TextField(
                              controller: _textController,
                              style: AppTypography.bodyMd,
                              onSubmitted: (value) => _sendMessage(),
                              decoration: InputDecoration(
                                hintText: 'Ask AdvisorAI',
                                hintStyle: AppTypography.bodySm.copyWith(
                                  color: AppColors.onSurfaceVariant.withOpacity(0.5),
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _sendMessage(),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [AppColors.primaryContainer, AppColors.fitnessViolet],
                                ),
                              ),
                              child: const Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFormattedText(String text, TextStyle baseStyle) {
    final List<InlineSpan> spans = [];
    final RegExp regex = RegExp(r'\*\*(.*?)\*\*|\*(.*?)\*');
    int lastMatchEnd = 0;

    for (final Match match in regex.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: baseStyle,
        ));
      }

      if (match.group(1) != null) {
        // Bold text (**...**)
        spans.add(TextSpan(
          text: match.group(1),
          style: baseStyle.copyWith(
            fontWeight: FontWeight.w700,
            color: baseStyle.color?.withOpacity(1.0) ?? Colors.white,
          ),
        ));
      } else if (match.group(2) != null) {
        // Italic text (*...*)
        spans.add(TextSpan(
          text: match.group(2),
          style: baseStyle.copyWith(
            fontStyle: FontStyle.italic,
          ),
        ));
      }

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: baseStyle,
      ));
    }

    return Text.rich(
      TextSpan(children: spans),
      style: baseStyle,
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12.0, left: 48.0),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withOpacity(0.85),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (msg.attachments.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: msg.attachments.map((att) {
                    if (att.isImage) {
                      return GestureDetector(
                        onTap: () => _showImagePreviewDialog(att),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            att.bytes,
                            width: 140,
                            height: 140,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    }
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.description_rounded, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            att.fileName,
                            style: AppTypography.bodySm.copyWith(
                              fontSize: 11,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                if (msg.text.isNotEmpty) const SizedBox(height: 8),
              ],
              if (msg.text.isNotEmpty)
                _buildFormattedText(
                  msg.text,
                  AppTypography.bodyMd.copyWith(color: Colors.white),
                ),
            ],
          ),
        ),
      );
    }

    final isErrorMessage = msg.text.startsWith('⚠️');

    // Remove raw bullet points from body text if they are rendered separately as action items
    String bodyText = msg.text;
    if (msg.actionItems.isNotEmpty) {
      final lines = msg.text.split('\n');
      final nonBullets = lines.where((l) {
        final t = l.trim();
        return !t.startsWith('- ') && !t.startsWith('* ') && !t.startsWith('• ');
      }).toList();
      final filtered = nonBullets.join('\n').trim();
      if (filtered.isNotEmpty) {
        bodyText = filtered;
      }
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12.0, right: 32.0),
        child: GlassContainer(
          padding: const EdgeInsets.all(16.0),
          borderRadius: 20.0,
          fillColor: isErrorMessage
              ? const Color(0xFF7F1D1D).withOpacity(0.25)
              : AppColors.surface.withOpacity(0.75),
          borderColor: isErrorMessage
              ? const Color(0xFFEF4444).withOpacity(0.5)
              : AppColors.glassBorderBright,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Advisor AI Header
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isErrorMessage
                          ? const LinearGradient(
                              colors: [Color(0xFFDC2626), Color(0xFFF59E0B)],
                            )
                          : const LinearGradient(
                              colors: [AppColors.primaryContainer, AppColors.fitnessViolet],
                            ),
                    ),
                    child: Icon(
                      isErrorMessage ? Icons.warning_amber_rounded : Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isErrorMessage ? 'AdvisorAI Status' : 'AdvisorAI',
                    style: AppTypography.titleMd.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isErrorMessage ? const Color(0xFFFCA5A5) : Colors.white,
                    ),
                  ),
                  const Spacer(),
                  if (msg.persona != null && !isErrorMessage)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        msg.persona!,
                        style: AppTypography.labelCaps.copyWith(
                          fontSize: 9,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              // Response Text with inline formatting
              _buildFormattedText(
                bodyText,
                AppTypography.bodyMd.copyWith(
                  height: 1.45,
                  color: isErrorMessage ? const Color(0xFFFEE2E2) : AppColors.onSurface,
                ),
              ),

              // Actionable Items / Quick Bullets
              if (msg.actionItems.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(color: AppColors.glassBorder, height: 1),
                const SizedBox(height: 10),
                Text(
                  'Recommended Actions',
                  style: AppTypography.labelCaps.copyWith(
                    fontSize: 10,
                    color: AppColors.electricCyan,
                  ),
                ),
                const SizedBox(height: 6),
                ...msg.actionItems.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 14,
                          color: AppColors.agriEmerald,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _buildFormattedText(
                            item,
                            AppTypography.bodySm.copyWith(
                              fontSize: 12,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Modal Sheet for managing and browsing multi-session conversations
class _ChatSessionsModal extends StatefulWidget {
  final WeatherProvider provider;

  const _ChatSessionsModal({required this.provider});

  @override
  State<_ChatSessionsModal> createState() => _ChatSessionsModalState();
}

class _ChatSessionsModalState extends State<_ChatSessionsModal> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showRenameDialog(ChatSession session) {
    final nameController = TextEditingController(text: session.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.glassBorderBright),
        ),
        title: Text('Rename Conversation', style: AppTypography.titleMd),
        content: TextField(
          controller: nameController,
          style: AppTypography.bodyMd,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter conversation title',
            hintStyle: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
            filled: true,
            fillColor: AppColors.surface.withOpacity(0.5),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryContainer),
            onPressed: () {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                widget.provider.renameChatSession(session.id, newName);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatSessionTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final sessions = widget.provider.chatSessions.where((s) {
      if (_searchQuery.isEmpty) return true;
      return s.title.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.96),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: AppColors.glassBorderBright),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header with "+ New Chat" Button
            Row(
              children: [
                Text(
                  'Recent Conversations',
                  style: AppTypography.headlineMd.copyWith(fontSize: 18),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                  label: const Text(
                    'New Chat',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  onPressed: () {
                    widget.provider.createNewChatSession();
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Search Bar
            TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: AppTypography.bodyMd,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.onSurfaceVariant, size: 20),
                hintText: 'Search conversations...',
                hintStyle: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant.withOpacity(0.5)),
                filled: true,
                fillColor: AppColors.surface.withOpacity(0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.glassBorder),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              ),
            ),
            const SizedBox(height: 12),

            // Session List
            Expanded(
              child: sessions.isEmpty
                  ? Center(
                      child: Text(
                        _searchQuery.isNotEmpty ? 'No conversations found' : 'No recent chats',
                        style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    )
                  : ListView.separated(
                      itemCount: sessions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final session = sessions[index];
                        final isActive = session.id == widget.provider.activeSessionId;

                        return InkWell(
                          onTap: () {
                            widget.provider.switchChatSession(session.id);
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.primary.withOpacity(0.12)
                                  : AppColors.surface.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isActive
                                    ? AppColors.primary.withOpacity(0.6)
                                    : AppColors.glassBorder,
                                width: isActive ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? AppColors.primary.withOpacity(0.2)
                                        : Colors.white.withOpacity(0.05),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isActive ? Icons.chat_bubble_rounded : Icons.chat_bubble_outline_rounded,
                                    color: isActive ? AppColors.primary : AppColors.onSurfaceVariant,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              session.title,
                                              style: AppTypography.titleMd.copyWith(
                                                fontSize: 14,
                                                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                                                color: isActive ? Colors.white : AppColors.onSurface,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (isActive)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              margin: const EdgeInsets.only(left: 6),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                'Active',
                                                style: AppTypography.labelCaps.copyWith(
                                                  fontSize: 9,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          Text(
                                            _formatSessionTime(session.updatedAt),
                                            style: AppTypography.bodySm.copyWith(
                                              fontSize: 11,
                                              color: AppColors.onSurfaceVariant,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '• ${session.messages.length} messages',
                                            style: AppTypography.bodySm.copyWith(
                                              fontSize: 11,
                                              color: AppColors.onSurfaceVariant.withOpacity(0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert_rounded, color: AppColors.onSurfaceVariant, size: 20),
                                  color: const Color(0xFF0F172A),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: const BorderSide(color: AppColors.glassBorderBright),
                                  ),
                                  onSelected: (action) {
                                    if (action == 'rename') {
                                      _showRenameDialog(session);
                                    } else if (action == 'delete') {
                                      widget.provider.deleteChatSession(session.id);
                                    }
                                  },
                                  itemBuilder: (ctx) => [
                                    const PopupMenuItem(
                                      value: 'rename',
                                      child: Row(
                                        children: [
                                          Icon(Icons.drive_file_rename_outline_rounded, size: 18, color: Colors.white),
                                          SizedBox(width: 8),
                                          Text('Rename Conversation', style: TextStyle(color: Colors.white, fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.alertRed),
                                          const SizedBox(width: 8),
                                          Text('Delete Conversation', style: TextStyle(color: AppColors.alertRed, fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated typing indicator widget with pulsing dots and live status
class _AnimatedTypingIndicator extends StatefulWidget {
  const _AnimatedTypingIndicator();

  @override
  State<_AnimatedTypingIndicator> createState() => _AnimatedTypingIndicatorState();
}

class _AnimatedTypingIndicatorState extends State<_AnimatedTypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      borderRadius: 20.0,
      fillColor: AppColors.surface.withOpacity(0.9),
      borderColor: AppColors.primaryContainer.withOpacity(0.4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.primaryContainer, AppColors.fitnessViolet],
              ),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 13),
          ),
          const SizedBox(width: 10),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (index) {
                  final delay = index * 0.2;
                  final progress = (_controller.value - delay) % 1.0;
                  final bounce = (progress >= 0 && progress <= 0.5)
                      ? (1.0 - (progress * 2 - 0.5).abs() * 2)
                      : 0.0;
                  final double dy = -3.5 * bounce;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2.0),
                    transform: Matrix4.translationValues(0, dy, 0),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.4 + (0.6 * bounce)),
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(width: 10),
          Text(
            'AdvisorAI is analyzing live telemetry...',
            style: AppTypography.bodySm.copyWith(
              fontSize: 11,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
