import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design/design_system.dart';
import '../../../../repositories/repositories.dart';

class HelpPage extends ConsumerStatefulWidget {
  const HelpPage({super.key});

  @override
  ConsumerState<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends ConsumerState<HelpPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int? _expandedFaq;
  bool _isCreatingTicket = false;
  final _ticketFormKey = GlobalKey<FormState>();
  final _ticketTitleController = TextEditingController();
  final _ticketDescController = TextEditingController();
  String _ticketCategory = 'Order Issue';

  final List<Map<String, String>> _faqs = [
    {
      'q': 'How do I accept an order?',
      'a':
          'When a new order arrives, it appears in your Dashboard under "New Incoming Orders". Tap "Accept" to confirm it, or "Reject" if you are unable to fulfil it. Accepted orders move to the Active tab in Orders.',
    },
    {
      'q': 'How do payouts work?',
      'a':
          'LNDRY processes vendor payouts every 7 days. After deducting the platform fee (₹15 per order) and GST, the remaining amount is transferred to your registered bank account via NEFT/IMPS.',
    },
    {
      'q': 'How do I change my working hours?',
      'a':
          'Go to Profile → Pickup Slots (or Quick Actions → Slots on Dashboard). Here you can add, edit, or remove time slots for each day of the week. You can also enable/disable individual slots.',
    },
    {
      'q': 'How do I contact the customer?',
      'a':
          'Open the Order Details page for the specific order. You will see the customer\'s name and a "Call Customer" button that dials them directly. Note: the customer\'s full phone number is masked for privacy until the order is accepted.',
    },
    {
      'q': 'What does "Pending" status mean?',
      'a':
          'Pending orders are new orders placed by customers that are waiting for your acceptance. You have a time window to accept or reject them. After the window expires, they are auto-rejected.',
    },
    {
      'q': 'How do I update garment prices?',
      'a':
          'Navigate to Profile → Garment Pricing or use the Catalogue tab. Select a service, then add/edit/delete individual garment rates. Changes take effect immediately for new orders.',
    },
    {
      'q': 'Can I manage multiple employees?',
      'a':
          'Yes. Go to Profile → Staff Management. You can add employees, assign roles (Manager, Washer, Ironer, Packer), set permissions, toggle their active status, and reset their passwords.',
    },
    {
      'q': 'What is the platform fee?',
      'a':
          'LNDRY charges a platform fee of ₹15 per order for connecting you with customers, payment processing, and operational support. GST at 18% applies on the platform fee only.',
    },
  ];

  // Live ticket list fetched from backend (replaces _demoTickets hardcoded list)
  List<Map<String, dynamic>> _tickets = [];
  bool _ticketsLoading = false;
  String? _ticketsError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTickets();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ticketTitleController.dispose();
    _ticketDescController.dispose();
    super.dispose();
  }

  Future<void> _loadTickets() async {
    if (!mounted) return;
    setState(() { _ticketsLoading = true; _ticketsError = null; });
    try {
      final repo = ref.read(vendorRepositoryProvider);
      final list = await repo.getSupportTickets();
      if (mounted) setState(() { _tickets = List<Map<String, dynamic>>.from(list); _ticketsLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _ticketsError = e.toString(); _ticketsLoading = false; });
    }
  }

  Future<void> _submitTicket() async {
    if (!_ticketFormKey.currentState!.validate()) return;
    setState(() => _isCreatingTicket = true);
    try {
      final repo = ref.read(vendorRepositoryProvider);
      final ticket = await repo.createSupportTicket(
        title: _ticketTitleController.text.trim(),
        description: _ticketDescController.text.trim(),
        category: _ticketCategory,
      );
      if (mounted) {
        setState(() {
          _tickets.insert(0, Map<String, dynamic>.from(ticket));
          _isCreatingTicket = false;
        });
        Navigator.pop(context);
        // Switch to the Tickets tab so the user sees the new ticket
        _tabController.animateTo(2);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Support ticket created! We will respond within 24 hours.'),
            backgroundColor: Color(0xFF11998e),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreatingTicket = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create ticket: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCreateTicketSheet() {
    _ticketTitleController.clear();
    _ticketDescController.clear();
    _ticketCategory = 'Order Issue';
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20.w, right: 20.w, top: 24.h,
          ),
          child: Form(
            key: _ticketFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Create Support Ticket',
                    style: AppTypography.headlineMedium
                        .copyWith(fontWeight: FontWeight.bold)),
                SizedBox(height: 16.h),
                DropdownButtonFormField<String>(
                  value: _ticketCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Order Issue', child: Text('Order Issue')),
                    DropdownMenuItem(value: 'Payout', child: Text('Payout')),
                    DropdownMenuItem(value: 'Technical', child: Text('Technical')),
                    DropdownMenuItem(value: 'Account', child: Text('Account')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (v) => setS(() => _ticketCategory = v ?? 'Other'),
                ),
                SizedBox(height: 12.h),
                TextFormField(
                  controller: _ticketTitleController,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    hintText: 'Brief description of your issue',
                    prefixIcon: Icon(Icons.title_rounded),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                SizedBox(height: 12.h),
                TextFormField(
                  controller: _ticketDescController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Provide more details about your issue...',
                    prefixIcon: Icon(Icons.description_outlined),
                    alignLabelWithHint: true,
                  ),
                  validator: (v) =>
                      v == null || v.length < 10 ? 'Please provide more details' : null,
                ),
                SizedBox(height: 20.h),
                ElevatedButton(
                  onPressed: _isCreatingTicket ? null : _submitTicket,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                  ),
                  child: _isCreatingTicket
                      ? SizedBox(
                          width: 20.r, height: 20.r,
                          child: const CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
                      : const Text('Submit Ticket'),
                ),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canPop = context.canPop();
    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go('/profile');
      },
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8F9FD),
        appBar: AppBar(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: isDark ? AppColors.white : AppColors.textBlack),
            onPressed: () => context.canPop() ? context.pop() : context.go('/profile'),
          ),
          title: Text(
            'Help & Support',
            style: AppTypography.headlineMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.white : AppColors.textBlack),
          ),
          bottom: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3.h,
            tabs: const [
              Tab(text: 'Contact'),
              Tab(text: 'FAQ'),
              Tab(text: 'Tickets'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildContactTab(isDark),
            _buildFaqTab(isDark),
            _buildTicketsTab(isDark),
          ],
        ),
      ),
    );
  }

  // ── Contact Tab ────────────────────────────────────────────────────────────

  Widget _buildContactTab(bool isDark) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero Banner
          Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Column(
              children: [
                Icon(Icons.support_agent_rounded, size: 56.r, color: AppColors.white),
                SizedBox(height: 12.h),
                Text('LNDRY Partner Support',
                    style: AppTypography.headlineSmall
                        .copyWith(fontWeight: FontWeight.bold, color: AppColors.white)),
                SizedBox(height: 4.h),
                Text(
                  'We are here to help! Reach us through any channel below.\nAvailable Mon–Sat, 9 AM – 7 PM IST.',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.white.withValues(alpha: 0.8)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),

          Text('Reach Us',
              style: AppTypography.headlineSmall
                  .copyWith(fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.white : AppColors.textBlack)),
          SizedBox(height: 12.h),

          _buildContactCard(
            isDark: isDark,
            icon: Icons.phone_rounded,
            color: const Color(0xFF11998e),
            title: 'Call Support',
            subtitle: '+91 1800-123-5678 (Toll Free)',
            actionLabel: 'Call Now',
            onTap: () => _showSnackBar('Calling LNDRY Support...'),
          ),
          SizedBox(height: 12.h),
          _buildContactCard(
            isDark: isDark,
            icon: Icons.email_outlined,
            color: const Color(0xFF0083B0),
            title: 'Email Support',
            subtitle: 'vendor-support@lndry.app',
            actionLabel: 'Send Email',
            onTap: () => _showSnackBar('Opening email client...'),
          ),
          SizedBox(height: 12.h),
          _buildContactCard(
            isDark: isDark,
            icon: Icons.chat_rounded,
            color: const Color(0xFF25D366),
            title: 'WhatsApp Support',
            subtitle: '+91 98765 43210',
            actionLabel: 'Open WhatsApp',
            onTap: () => _showSnackBar('Opening WhatsApp...'),
          ),
          SizedBox(height: 12.h),
          _buildContactCard(
            isDark: isDark,
            icon: Icons.confirmation_number_outlined,
            color: const Color(0xFF8E2DE2),
            title: 'Create Support Ticket',
            subtitle: 'Track your issue with a ticket ID',
            actionLabel: 'Create Ticket',
            onTap: () {
              _tabController.animateTo(2);
              Future.delayed(const Duration(milliseconds: 300), _showCreateTicketSheet);
            },
          ),

          SizedBox(height: 24.h),
          // SLA card
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: AppColors.outline.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Response Times',
                    style: AppTypography.bodyLarge
                        .copyWith(fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.white : AppColors.textBlack)),
                SizedBox(height: 12.h),
                _buildSlaRow(icon: Icons.phone_rounded, label: 'Phone / WhatsApp', value: 'Immediate', color: AppColors.success),
                _buildSlaRow(icon: Icons.email_outlined, label: 'Email', value: '< 4 hours', color: AppColors.primary),
                _buildSlaRow(icon: Icons.confirmation_number_outlined, label: 'Support Ticket', value: '< 24 hours', color: AppColors.warning),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard({
    required bool isDark,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isDark ? AppColors.darkSurface : AppColors.white,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Row(children: [
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Icon(icon, color: color, size: 24.r),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title,
                    style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.white : AppColors.textBlack)),
                Text(subtitle,
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
              ]),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(actionLabel,
                  style: AppTypography.bodySmall
                      .copyWith(color: color, fontWeight: FontWeight.bold)),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildSlaRow({required IconData icon, required String label, required String value, required Color color}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(children: [
        Icon(icon, size: 16.r, color: color),
        SizedBox(width: 10.w),
        Expanded(child: Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary))),
        Text(value, style: AppTypography.bodySmall.copyWith(color: color, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  // ── FAQ Tab ────────────────────────────────────────────────────────────────

  Widget _buildFaqTab(bool isDark) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.all(14.r),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Row(children: [
              Icon(Icons.lightbulb_outline_rounded, color: AppColors.primary, size: 22.r),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'Can\'t find your answer? Create a support ticket.',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.primary),
                ),
              ),
              TextButton(
                onPressed: () {
                  _tabController.animateTo(2);
                  Future.delayed(const Duration(milliseconds: 300), _showCreateTicketSheet);
                },
                style: TextButton.styleFrom(foregroundColor: AppColors.primary, padding: EdgeInsets.zero),
                child: const Text('Create'),
              ),
            ]),
          ),
          SizedBox(height: 16.h),
          ...List.generate(_faqs.length, (i) {
            final faq = _faqs[i];
            final isExpanded = _expandedFaq == i;
            return Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: Material(
                color: isDark ? AppColors.darkSurface : AppColors.white,
                borderRadius: BorderRadius.circular(16.r),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16.r),
                  onTap: () => setState(() => _expandedFaq = isExpanded ? null : i),
                  child: Padding(
                    padding: EdgeInsets.all(16.r),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(
                          width: 28.r, height: 28.r,
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Center(
                            child: Text('${i + 1}',
                                style: AppTypography.bodySmall
                                    .copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(faq['q']!,
                              style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.white : AppColors.textBlack)),
                        ),
                        Icon(
                          isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          color: AppColors.textSecondary,
                        ),
                      ]),
                      if (isExpanded) ...[
                        SizedBox(height: 12.h),
                        Divider(height: 1, color: AppColors.outline.withValues(alpha: 0.2)),
                        SizedBox(height: 12.h),
                        Text(faq['a']!,
                            style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textSecondary, height: 1.5)),
                      ],
                    ]),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Tickets Tab ────────────────────────────────────────────────────────────

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'RESOLVED': return const Color(0xFF11998e);
      case 'IN_PROGRESS': return const Color(0xFFF2994A);
      case 'OPEN': return const Color(0xFF0083B0);
      case 'CLOSED': return const Color(0xFF9E9E9E);
      default: return AppColors.primary;
    }
  }

  String _statusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'RESOLVED': return 'Resolved';
      case 'IN_PROGRESS': return 'In Progress';
      case 'OPEN': return 'Open';
      case 'CLOSED': return 'Closed';
      default: return status;
    }
  }

  String _relativeDate(String? isoDate) {
    if (isoDate == null) return '';
    final dt = DateTime.tryParse(isoDate);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return 'Just now';
  }

  Widget _buildTicketsTab(bool isDark) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: _showCreateTicketSheet,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create New Ticket'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: EdgeInsets.symmetric(vertical: 14.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
            ),
          ),
          SizedBox(height: 20.h),
          Text('Your Tickets',
              style: AppTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.white : AppColors.textBlack)),
          SizedBox(height: 12.h),
          if (_ticketsLoading)
            const Center(child: CircularProgressIndicator())
          else if (_ticketsError != null)
            Center(
              child: Column(children: [
                Text('Failed to load tickets', style: AppTypography.bodyMedium.copyWith(color: Colors.red)),
                SizedBox(height: 8.h),
                TextButton(onPressed: _loadTickets, child: const Text('Retry')),
              ]),
            )
          else if (_tickets.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32.h),
                child: Column(children: [
                  Icon(Icons.confirmation_number_outlined, size: 48.r, color: AppColors.textSecondary),
                  SizedBox(height: 12.h),
                  Text('No tickets yet', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
                  SizedBox(height: 4.h),
                  Text('Create a ticket and we will respond within 24 hours.',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center),
                ]),
              ),
            )
          else
            ..._tickets.map((ticket) => Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Material(
                color: isDark ? AppColors.darkSurface : AppColors.white,
                borderRadius: BorderRadius.circular(16.r),
                child: Padding(
                  padding: EdgeInsets.all(16.r),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(ticket['ticket_ref'] as String? ?? '',
                          style: AppTypography.bodySmall.copyWith(
                              color: AppColors.primary, fontWeight: FontWeight.bold)),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: _statusColor(ticket['status'] as String? ?? '').withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(_statusLabel(ticket['status'] as String? ?? ''),
                            style: AppTypography.bodySmall.copyWith(
                                color: _statusColor(ticket['status'] as String? ?? ''),
                                fontWeight: FontWeight.bold,
                                fontSize: 10.sp)),
                      ),
                    ]),
                    SizedBox(height: 8.h),
                    Text(ticket['title'] as String? ?? '',
                        style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.white : AppColors.textBlack)),
                    SizedBox(height: 4.h),
                    Row(children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(ticket['category'] as String? ?? '',
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.primary, fontSize: 10.sp)),
                      ),
                      SizedBox(width: 8.w),
                      Text(_relativeDate(ticket['created_at'] as String?),
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                    ]),
                  ]),
                ),
              ),
            )),
        ],
      ),
    );
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
