/// LNDRY Asset Path Constants
/// All asset paths in one place — prevents typos and makes refactoring safe.
abstract final class AssetConstants {
  AssetConstants._();

  // ── Base Paths ────────────────────────────────────────────────────────────
  static const String _images = 'assets/images';
  static const String _icons = 'assets/icons';
  static const String _illustrations = 'assets/illustrations';
  static const String _lottie = 'assets/lottie';
  static const String _svg = 'assets/svg';

  // ── Images ────────────────────────────────────────────────────────────────
  static const String logoFull = 'assets/images/logo/lndry_logo.png';
  static const String logoMark = 'assets/images/logo/lndry_logo.png';
  static const String logoDark = 'assets/images/logo/lndry_logo.png';
  static const String splashBg = '$_images/splash_bg.png';
  static const String onboarding1 = '$_images/onboarding_1.png';
  static const String onboarding2 = '$_images/onboarding_2.png';
  static const String onboarding3 = '$_images/onboarding_3.png';
  static const String avatarPlaceholder = '$_images/avatar_placeholder.png';
  static const String servicePlaceholder = '$_images/service_placeholder.png';
  static const String logo = 'assets/images/logo/lndry_logo.png';
  static const String firstPickupBanner =
      '$_images/banners/first-pickup-v1.png';

  // ── Illustrations ─────────────────────────────────────────────────────────
  static const String emptyOrders = '$_illustrations/empty_orders.png';
  static const String emptySearch = '$_illustrations/empty_search.png';
  static const String emptyCart = '$_illustrations/empty_cart.png';
  static const String errorIllustration =
      '$_illustrations/error_illustration.png';
  static const String noInternet = '$_illustrations/no_internet.png';
  static const String paymentSuccess = '$_illustrations/payment_success.png';
  static const String mapPlaceholder = '$_illustrations/map_placeholder.png';

  // ── Icons (SVG) ───────────────────────────────────────────────────────────
  static const String iconHome = '$_icons/home.svg';
  static const String iconOrders = '$_icons/orders.svg';
  static const String iconServices = '$_icons/services.svg';
  static const String iconProfile = '$_icons/profile.svg';
  static const String iconWallet = '$_icons/wallet.svg';
  static const String iconNotification = '$_icons/notification.svg';
  static const String iconLocation = '$_icons/location.svg';
  static const String iconSearch = '$_icons/search.svg';
  static const String iconFilter = '$_icons/filter.svg';
  static const String iconCart = '$_icons/cart.svg';
  static const String iconStar = '$_icons/star.svg';
  static const String iconWash = '$_icons/wash.svg';
  static const String iconIron = '$_icons/iron.svg';
  static const String iconDryClean = '$_icons/dry_clean.svg';
  static const String iconFold = '$_icons/fold.svg';
  static const String iconDelivery = '$_icons/delivery.svg';
  static const String iconPickup = '$_icons/pickup.svg';
  static const String iconPhone = '$_icons/phone.svg';
  static const String iconMail = '$_icons/mail.svg';
  static const String iconLock = '$_icons/lock.svg';
  static const String iconGoogle = '$_icons/google.svg';
  static const String iconApple = '$_icons/apple.svg';

  // Service icons from the approved LNDRY UI kit.
  static const String serviceWashFold = '$_icons/services/wash-fold.svg';
  static const String serviceWashIron = '$_icons/services/wash-iron.svg';
  static const String serviceDryCleaning = '$_icons/services/dry-cleaning.svg';
  static const String serviceSteamPress = '$_icons/services/steam-press.svg';
  static const String serviceShoeCare = '$_icons/services/shoe-care.svg';
  static const String serviceBagCare = '$_icons/services/bag-care.svg';
  static const String servicePremiumGarmentCare =
      '$_icons/services/premium-garment-care.svg';
  static const String serviceTailoring = '$_icons/services/tailoring.svg';
  static const String serviceCurtainCleaning =
      '$_icons/services/curtain-cleaning.svg';
  static const String serviceCarpetCleaning =
      '$_icons/services/carpet-cleaning.svg';
  static const String serviceBlanketCleaning =
      '$_icons/services/blanket-cleaning.svg';

  // ── Lottie Animations ─────────────────────────────────────────────────────
  static const String animLoading = '$_lottie/loading.json';
  static const String animSuccess = '$_lottie/success.json';
  static const String animEmpty = '$_lottie/empty.json';
  static const String animError = '$_lottie/error.json';
  static const String animDelivery = '$_lottie/delivery.json';
  static const String animWashing = '$_lottie/washing.json';
  static const String animSplash = '$_lottie/splash.json';
  static const String animNoInternet = '$_lottie/no_internet.json';

  // ── General SVGs ──────────────────────────────────────────────────────────
  static const String svgWave = '$_svg/wave.svg';
}
