import "package:flutter/material.dart";

import "../data/ledger_repository.dart";

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.repo, required this.onDone});

  final LedgerRepository repo;
  final VoidCallback onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _page = PageController();
  int _i = 0;
  final _nameCtrl = TextEditingController();

  static const _total = 4;

  @override
  void dispose() {
    _page.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_i < _total - 1) {
      _page.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _prev() {
    if (_i > 0) {
      _page.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _finish() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập tên của bạn")),
      );
      return;
    }
    await widget.repo.setUserName(name);
    await widget.repo.setOnboarded(true);
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 1000;
    final isLast = _i == _total - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top bar: only the skip link, right-aligned
            if (!isLast)
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 6, right: 12),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () => _page.animateToPage(
                      _total - 1,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                    ),
                    child: const Text("Bỏ qua"),
                  ),
                ),
              )
            else
              const SizedBox(height: 36),

            // Page content
            Expanded(
              child: PageView(
                controller: _page,
                onPageChanged: (v) => setState(() => _i = v),
                children: [
                  _IntroPage(
                    title: "Smart Ledger",
                    body:
                        "Ghi chép thu chi thông minh — lưu trữ ngay trên thiết bị — không cần kết nối mạng.",
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                  _IntroPage(
                    title: "Ghi chép siêu tốc",
                    body:
                        "Chạm để nhập nhanh, chụp ảnh hoá đơn hoặc ghi âm giọng nói — tất cả trong vài giây.",
                    icon: Icons.bolt,
                  ),
                  _IntroPage(
                    title: "Đối soát thông minh",
                    body:
                        "Xem lại và phân loại giao dịch chờ bất cứ lúc nào, khi bạn có thời gian rảnh.",
                    icon: Icons.fact_check,
                  ),
                  _IntroPage(
                    title: "Quản lý thông thái",
                    body:
                        "Theo dõi thu chi qua biểu đồ trực quan — toàn bộ dữ liệu lưu riêng tư trên máy bạn.",
                    icon: Icons.insights,
                  ),
                ],
              ),
            ),

            // Centered step indicator dots
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_total, (idx) {
                  final active = idx == _i;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),

            // Bottom: prev / next or name input
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: isLast
                  ? Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isWide ? 460 : double.infinity,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              controller: _nameCtrl,
                              decoration: const InputDecoration(
                                labelText: "Nhập tên của bạn?",
                                hintText: "Ví dụ: Nguyễn Văn A",
                              ),
                              textCapitalization: TextCapitalization.words,
                              onSubmitted: (_) => _finish(),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _prev,
                                  icon: const Icon(
                                    Icons.arrow_back_rounded,
                                    size: 18,
                                  ),
                                  label: const Text("Quay lại"),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: _finish,
                                    child: const Text("Bắt đầu"),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_i > 0) ...[
                          OutlinedButton.icon(
                            onPressed: _prev,
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              size: 18,
                            ),
                            label: const Text("Trước"),
                          ),
                          const SizedBox(width: 16),
                        ],
                        FilledButton.icon(
                          onPressed: _next,
                          label: const Text("Tiếp theo"),
                          icon: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                          ),
                          iconAlignment: IconAlignment.end,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  const _IntroPage({
    required this.title,
    required this.body,
    required this.icon,
  });

  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 72, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(
            body,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
