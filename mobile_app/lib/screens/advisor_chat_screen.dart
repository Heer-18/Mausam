import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_message.dart';
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
    if (text.isEmpty) return;

    _textController.clear();
    context.read<WeatherProvider>().sendChatMessage(text);

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 180,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
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
                  const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    provider.cityName,
                    style: AppTypography.titleMd.copyWith(fontSize: 16),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.onSurfaceVariant, size: 18),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.cleaning_services_rounded, color: AppColors.onSurfaceVariant, size: 20),
                tooltip: 'Clear Chat',
                onPressed: () => provider.clearChatHistory(),
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
              // Subheader Card matching Stitch design
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: GlassContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  borderRadius: 20.0,
                  fillColor: AppColors.primaryContainer.withOpacity(0.1),
                  borderColor: AppColors.primaryContainer.withOpacity(0.3),
                  child: Row(
                    children: [
                      // Robot / AI Avatar Icon with Blue Glow
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [AppColors.primaryContainer, AppColors.fitnessViolet],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryContainer.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.smart_toy_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Title and Intelligence Label
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'advisorAI',
                                  style: AppTypography.headlineMd.copyWith(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    provider.activePersona.shortTitle,
                                    style: AppTypography.labelCaps.copyWith(
                                      fontSize: 9,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Powered by Gemini 2.5 Flash',
                              style: AppTypography.bodySm.copyWith(
                                fontSize: 11,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Green Status Dot (• Online)
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.agriEmerald,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Live API',
                            style: AppTypography.labelCaps.copyWith(
                              fontSize: 11,
                              color: AppColors.agriEmerald,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Quick Prompt Suggestion Chips (Horizontal Carousel)
              Container(
                height: 44,
                margin: const EdgeInsets.only(top: 8.0),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  scrollDirection: Axis.horizontal,
                  itemCount: quickPrompts.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final prompt = quickPrompts[index];
                    return ActionChip(
                      backgroundColor: AppColors.surface.withOpacity(0.6),
                      side: BorderSide(color: AppColors.glassBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      label: Text(
                        prompt,
                        style: AppTypography.bodySm.copyWith(
                          fontSize: 12,
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
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  itemCount: provider.chatMessages.length,
                  itemBuilder: (context, index) {
                    final msg = provider.chatMessages[index];
                    return _buildMessageBubble(msg);
                  },
                ),
              ),

              // Animated Chat Loading Bubble with Pulsing Dots
              if (provider.isChatLoading)
                const Padding(
                  padding: EdgeInsets.only(left: 16.0, right: 48.0, bottom: 12.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _AnimatedTypingIndicator(),
                  ),
                ),

              // Bottom Input Bar
              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                child: GlassContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  borderRadius: 28,
                  borderColor: AppColors.glassBorderBright,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.onSurfaceVariant),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => const PersonaModal(),
                          );
                        },
                      ),
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          style: AppTypography.bodyMd,
                          onSubmitted: (value) => _sendMessage(),
                          decoration: InputDecoration(
                            hintText: 'Ask advisorAI...',
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
                          width: 42,
                          height: 42,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [AppColors.primaryContainer, AppColors.fitnessViolet],
                            ),
                          ),
                          child: const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
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
          child: Text(
            msg.text,
            style: AppTypography.bodyMd.copyWith(
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    final isErrorMessage = msg.text.startsWith('⚠️');

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
                      isErrorMessage ? Icons.warning_amber_rounded : Icons.smart_toy_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isErrorMessage ? 'advisorAI Status' : 'advisorAI',
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

              // Response Text
              Text(
                msg.text,
                style: AppTypography.bodyMd.copyWith(
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
                  'RECOMMENDED ACTIONS',
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
                          child: Text(
                            item,
                            style: AppTypography.bodySm.copyWith(
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
            child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 13),
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
            'advisorAI is analyzing live telemetry...',
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
