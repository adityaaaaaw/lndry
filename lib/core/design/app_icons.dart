import 'package:flutter/material.dart';

/// LNDRY Design Token: Icon Map
/// Swaps icon sets in one place.
abstract final class AppIcons {
  AppIcons._();

  // ── Navigation ────────────────────────────────────────────────────────────
  static const IconData home           = Icons.home_rounded;
  static const IconData homeOutlined   = Icons.home_outlined;
  static const IconData search         = Icons.search_rounded;
  static const IconData orders         = Icons.receipt_long_rounded;
  static const IconData ordersOutlined = Icons.receipt_long_outlined;
  static const IconData profile        = Icons.person_rounded;
  static const IconData profileOutlined= Icons.person_outline_rounded;
  static const IconData cart           = Icons.shopping_cart_rounded;
  static const IconData cartOutlined   = Icons.shopping_cart_outlined;
  static const IconData notifications  = Icons.notifications_rounded;
  static const IconData notificationsOutlined = Icons.notifications_outlined;

  // ── Actions ───────────────────────────────────────────────────────────────
  static const IconData add            = Icons.add_rounded;
  static const IconData remove         = Icons.remove_rounded;
  static const IconData delete         = Icons.delete_outline_rounded;
  static const IconData edit           = Icons.edit_outlined;
  static const IconData close          = Icons.close_rounded;
  static const IconData done           = Icons.done_rounded;
  static const IconData filter         = Icons.tune_rounded;
  static const IconData sort           = Icons.sort_rounded;
  static const IconData share          = Icons.share_outlined;
  static const IconData copy           = Icons.copy_outlined;
  static const IconData refresh        = Icons.refresh_rounded;
  static const IconData upload         = Icons.upload_outlined;
  static const IconData download       = Icons.download_outlined;
  static const IconData camera         = Icons.camera_alt_outlined;
  static const IconData gallery        = Icons.photo_library_outlined;

  // ── Navigation arrows ─────────────────────────────────────────────────────
  static const IconData back           = Icons.arrow_back_ios_new_rounded;
  static const IconData forward        = Icons.arrow_forward_ios_rounded;
  static const IconData chevronRight   = Icons.chevron_right_rounded;
  static const IconData chevronDown    = Icons.keyboard_arrow_down_rounded;
  static const IconData chevronUp      = Icons.keyboard_arrow_up_rounded;
  static const IconData expand         = Icons.expand_more_rounded;

  // ── Status & Feedback ─────────────────────────────────────────────────────
  static const IconData success        = Icons.check_circle_rounded;
  static const IconData error          = Icons.error_rounded;
  static const IconData warning        = Icons.warning_rounded;
  static const IconData info           = Icons.info_rounded;
  static const IconData star           = Icons.star_rounded;
  static const IconData starOutlined   = Icons.star_border_rounded;
  static const IconData starHalf       = Icons.star_half_rounded;
  static const IconData favorite       = Icons.favorite_rounded;
  static const IconData favoriteOutlined = Icons.favorite_border_rounded;
  static const IconData help           = Icons.help_outline_rounded;

  // ── Laundry-specific ──────────────────────────────────────────────────────
  static const IconData laundry        = Icons.local_laundry_service_rounded;
  static const IconData dry            = Icons.dry_cleaning_rounded;
  static const IconData iron           = Icons.iron_rounded;
  static const IconData delivery       = Icons.delivery_dining_rounded;
  static const IconData pickup         = Icons.directions_bike_rounded;
  static const IconData washer         = Icons.local_laundry_service_outlined;
  static const IconData weight         = Icons.scale_outlined;
  static const IconData timer          = Icons.timer_outlined;

  // ── User & Auth ───────────────────────────────────────────────────────────
  static const IconData phone          = Icons.phone_rounded;
  static const IconData email          = Icons.email_outlined;
  static const IconData lock           = Icons.lock_outline_rounded;
  static const IconData lockOpen       = Icons.lock_open_rounded;
  static const IconData visibility     = Icons.visibility_outlined;
  static const IconData visibilityOff  = Icons.visibility_off_outlined;
  static const IconData logout         = Icons.logout_rounded;
  static const IconData settings       = Icons.settings_outlined;

  // ── Location ──────────────────────────────────────────────────────────────
  static const IconData location       = Icons.location_on_rounded;
  static const IconData locationOutlined = Icons.location_on_outlined;
  static const IconData map            = Icons.map_outlined;
  static const IconData navigate       = Icons.navigation_rounded;
  static const IconData myLocation     = Icons.my_location_rounded;

  // ── Payment ───────────────────────────────────────────────────────────────
  static const IconData wallet         = Icons.account_balance_wallet_rounded;
  static const IconData walletOutlined = Icons.account_balance_wallet_outlined;
  static const IconData payment        = Icons.payment_rounded;
  static const IconData creditCard     = Icons.credit_card_rounded;
  static const IconData upi            = Icons.currency_rupee_rounded;

  // ── Misc ──────────────────────────────────────────────────────────────────
  static const IconData store          = Icons.store_rounded;
  static const IconData tag            = Icons.local_offer_rounded;
  static const IconData coupon         = Icons.confirmation_number_outlined;
  static const IconData support        = Icons.support_agent_rounded;
  static const IconData document       = Icons.description_outlined;
  static const IconData calendar       = Icons.calendar_today_rounded;
  static const IconData clock          = Icons.access_time_rounded;
  static const IconData trending       = Icons.trending_up_rounded;
  static const IconData noInternet     = Icons.cloud_off_outlined;
  static const IconData emptyBox       = Icons.inbox_outlined;
}
