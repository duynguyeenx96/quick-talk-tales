import 'package:flutter/widgets.dart';

/// Minimal bilingual strings.  Add keys here as the app grows.
///
/// Usage:
///   final s = AppStrings.of(context);
///   Text(s.homeTitle)
class AppStrings {
  final String lang;
  const AppStrings(this.lang);

  static AppStrings of(context) => _AppLocaleScope.of(context);

  // ── Home ────────────────────────────────────────────────────────────────────
  String get homeTitle => _t('Quick Talk Tales', 'Quick Talk Tales');
  String get startChallenge => _t('Start Challenge', 'Bắt đầu thử thách');
  String get history => _t('History', 'Lịch sử');
  String get leaderboard => _t('Leaderboard', 'Bảng xếp hạng');
  String get profileTitle => _t('Profile', 'Hồ sơ');

  // ── Profile ─────────────────────────────────────────────────────────────────
  String get editProfile => _t('Edit Profile', 'Chỉnh sửa hồ sơ');
  String get languageLabel => _t('Language', 'Ngôn ngữ');
  String get subscriptionLabel => _t('Subscription', 'Gói đăng ký');
  String get freePlan => _t('Free Plan', 'Gói miễn phí');
  String get premiumPlan => _t('Premium', 'Gói Premium');
  String get upgradeToPremium => _t('Upgrade to Premium', 'Nâng cấp Premium');
  String get logoutLabel => _t('Log Out', 'Đăng xuất');
  String get saveChanges => _t('Save changes', 'Lưu thay đổi');
  String get displayName => _t('Display Name', 'Tên hiển thị');

  // ── Subscription ────────────────────────────────────────────────────────────
  String get unlockEverything => _t('Unlock Everything', 'Mở khóa tất cả');
  String get alreadyPremium => _t("You're already Premium!", 'Bạn đang dùng Premium!');
  String get monthly => _t('Monthly', 'Hàng tháng');
  String get yearly => _t('Yearly', 'Hàng năm');

  // ── Payment ─────────────────────────────────────────────────────────────────
  String get bankTransfer => _t('Bank Transfer', 'Chuyển khoản');
  String get scanQr => _t('Scan with banking app', 'Quét bằng app ngân hàng');
  String get waitingPayment => _t('Waiting for payment', 'Chờ thanh toán');
  String get paymentConfirmed => _t('Payment Confirmed!', 'Thanh toán thành công!');
  String get orderExpired => _t('Order expired', 'Đơn hàng hết hạn');
  String get generateNewQr => _t('Generate New QR', 'Tạo QR mới');
  String get startExploring => _t('Start Exploring', 'Khám phá ngay');

  // ── Leaderboard ─────────────────────────────────────────────────────────────
  String get totalScore => _t('Total Score', 'Tổng điểm');
  String get challengesLabel => _t('Challenges', 'Thử thách');
  String get yourRank => _t('Your Rank', 'Xếp hạng của bạn');
  String get youLabel => _t('You', 'Bạn');

  // ── Common ──────────────────────────────────────────────────────────────────
  String get retry => _t('Retry', 'Thử lại');
  String get loading => _t('Loading...', 'Đang tải...');

  String _t(String en, String vi) => lang == 'vi' ? vi : en;
}

/// InheritedWidget that provides [AppStrings] down the tree.
class _AppLocaleScope extends InheritedWidget {
  final AppStrings strings;

  const _AppLocaleScope({required this.strings, required super.child});

  static AppStrings of(context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_AppLocaleScope>();
    return scope?.strings ?? const AppStrings('en');
  }

  @override
  bool updateShouldNotify(_AppLocaleScope old) => strings.lang != old.strings.lang;
}

/// Wrap your widget tree with this to provide localized strings.
class AppLocaleProvider extends StatelessWidget {
  final String lang;
  final Widget child;

  const AppLocaleProvider({super.key, required this.lang, required this.child});

  @override
  Widget build(context) =>
      _AppLocaleScope(strings: AppStrings(lang), child: child);
}
