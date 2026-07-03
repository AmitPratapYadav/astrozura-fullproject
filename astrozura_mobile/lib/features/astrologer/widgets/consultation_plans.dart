// lib/screens/astrologer/widgets/consultation_plans.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/astrologer/astrologer_model.dart';
import '../screens/schedule_session_screen.dart';

class ConsultationPlans extends StatefulWidget {
  final AstrologerModel astrologer;

  const ConsultationPlans({super.key, required this.astrologer});

  @override
  State<ConsultationPlans> createState() => _ConsultationPlansState();
}

class _ConsultationPlansState extends State<ConsultationPlans> {
  final int _selectedIndex = 1; // default to 2nd (popular) plan

  @override
  Widget build(BuildContext context) {
    final plans =
        widget.astrologer.consultationPlans.where((p) => p.price > 0).toList();

    if (plans.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No consultation plans available.'),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section header ─────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 3,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4A73A),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Consultation Plans',
                style: GoogleFonts.playfairDisplay(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: const Color(0xFF2E2A72),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            'Choose the session duration that suits you',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.black45,
            ),
          ),

          const SizedBox(height: 16),

          // ── Tab toggle: Chat / Call ────────────────────────────────────
          _TypeToggle(astrologer: widget.astrologer),
        ],
      ),
    );
  }
}

// ── Type toggle + plan cards ──────────────────────────────────────────────────

class _TypeToggle extends StatefulWidget {
  final AstrologerModel astrologer;
  const _TypeToggle({required this.astrologer});

  @override
  State<_TypeToggle> createState() => _TypeToggleState();
}

class _TypeToggleState extends State<_TypeToggle> {
  String _activeType = 'chat';

  List<ConsultationPlan> get _plans => widget.astrologer.consultationPlans
      .where((p) => p.price > 0 && p.type == _activeType)
      .toList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Toggle ────────────────────────────────────────────────────────

        const SizedBox(height: 16),

        // ── Plan cards grid ───────────────────────────────────────────────
        if (_plans.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'No $_activeType plans available.',
                style: const TextStyle(color: Colors.black45),
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _plans.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 18,
              childAspectRatio: 0.68,
            ),
            itemBuilder: (context, index) {
              final isPopular = index == 1;
              final plan = _plans[index];
              return _PlanCard(
                plan: plan,
                astrologer: widget.astrologer,
                isPopular: isPopular,
              );
            },
          ),
      ],
    );
  }

  Widget _toggleBtn(String type, IconData icon, String label) {
    final isActive = _activeType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive ? const Color(0xFFD4A73A) : Colors.black45,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                  color: isActive ? const Color(0xFF2E2A72) : Colors.black45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Plan card ─────────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final ConsultationPlan plan;
  final AstrologerModel astrologer;
  final bool isPopular;

  const _PlanCard({
    required this.plan,
    required this.astrologer,
    this.isPopular = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // ── Card ──────────────────────────────────────────────────────────
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ScheduleSessionScreen(
                astrologer: astrologer,
                preselectedType: plan.type,
                preselectedDuration: plan.duration,
              ),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                    isPopular ? const Color(0xFFD4A73A) : Colors.grey.shade200,
                width: isPopular ? 1.8 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isPopular
                      ? const Color(0xFFD4A73A).withOpacity(0.12)
                      : Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Icon circle
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isPopular
                        ? const Color(0xFFFFF3CD)
                        : const Color(0xFFEEEEF8),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    plan.type == 'chat'
                        ? Icons.chat_bubble_outline_rounded
                        : Icons.headset_mic_outlined,
                    color: isPopular
                        ? const Color(0xFFD4A73A)
                        : const Color(0xFF5B63D3),
                    size: 22,
                  ),
                ),

                const SizedBox(height: 8),

                // Duration
                Text(
                  '${plan.duration} min',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2E2A72),
                  ),
                ),

                // Per-minute rate
                Text(
                  '₹${(plan.price / plan.duration).toStringAsFixed(0)}/min',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black45,
                  ),
                ),

                const SizedBox(height: 4),

                // Total price
                Text(
                  '₹${plan.price.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isPopular
                        ? const Color(0xFFD4A73A)
                        : const Color(0xFF2E2A72),
                  ),
                ),

                const SizedBox(height: 8),

                // Book button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ScheduleSessionScreen(
                          astrologer: astrologer,
                          preselectedType: plan.type,
                          preselectedDuration: plan.duration,
                        ),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPopular
                          ? const Color(0xFFD4A73A)
                          : const Color(0xFF5B63D3),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Book Now',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Popular badge ──────────────────────────────────────────────────
        if (isPopular)
          Positioned(
            top: -10,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4A73A),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD4A73A).withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt, size: 11, color: Colors.white),
                    SizedBox(width: 3),
                    Text(
                      'POPULAR',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
