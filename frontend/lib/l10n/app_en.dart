// English strings for SawitSense.
const Map<String, String> enStrings = {
  // App
  'app_title': 'SawitSense MY',
  'app_tagline': 'Sawit Kita, Harga Kita',
  'app_subtitle': 'CPO Price Tracker & OER Signal',

  // Navigation
  'nav_dashboard': 'Dashboard',
  'nav_calculator': 'Fair Price',
  'nav_history': 'Price History',

  // Dashboard
  'dashboard_title': 'Daily Price Dashboard',
  'cpo_spot_price': 'CPO Spot Price',
  'ffb_reference': 'FFB Reference Price (1% OER)',
  'per_tonne': '/tonne',
  'per_1pct': '/1% OER',
  'last_updated': 'Last updated',
  'source': 'Source',
  'no_data': 'No price data available',
  'demo_banner': 'Showing demo data — live data loads from MPOB BEPI',

  // Indicative-mode banner (Path C — see ADR-001)
  'indicative_banner_headline':
      'Indicative prices — not official MPOB FFB Reference Price',
  'indicative_banner_body':
      'MPOB has moved the Daily FFB Reference Price behind a licensee login. '
      'Until restored, regional prices shown are derived from MPOC daily CPO '
      'settlement and MPOB monthly OER. Use as guidance, not as a legal benchmark.',
  'indicative_banner_learn_more': 'Learn more (ADR-001)',
  'indicative_banner_link_copied': 'ADR-001 link copied to clipboard',
  'indicative_chip': 'Indicative',
  'region_north': 'North',
  'region_south': 'South',
  'region_central': 'Central',
  'region_east_coast': 'East Coast',
  'region_sabah': 'Sabah',
  'region_sarawak': 'Sarawak',

  // Calculator
  'calc_title': 'Fair Price Calculator',
  'calc_subtitle': 'Formula: Price/mt = Price_1% x Graded_OER%',
  'calc_region': 'Select Region',
  'calc_price_1pct': 'Price per 1% OER (RM)',
  'calc_oer': 'Graded OER (%)',
  'calc_paid': 'Price Paid (RM/tonne) — optional',
  'calc_calculate': 'Calculate',
  'calc_fair_price': 'Fair Price',
  'calc_verdict': 'Verdict',
  'calc_gap': 'Gap',
  'calc_oer_tip': 'Each 1% OER = ~RM 42+/tonne difference',
  'verdict_green': 'FAIR — within 5% of MPOB benchmark',
  'verdict_amber': 'CAUTION — 5-15% below benchmark',
  'verdict_red': 'BELOW FAIR — more than 15% below benchmark',

  // History
  'history_title': 'CPO Price History',
  'history_subtitle': '30-day CPO spot price trend',
  'history_no_data': 'No historical data available yet',

  // Feedback
  'feedback_title': 'Feedback',
  'feedback_helpful': 'This is helpful!',
  'feedback_confusing': 'Something is confusing',
  'feedback_wrong': 'Price looks wrong',
  'feedback_thanks': 'Thank you for your feedback!',

  // Footer
  'footer_open_source': 'Open Source',
  'footer_github': 'View on GitHub',
  'footer_disclaimer':
      'Prices are from MPOB BEPI for reference only. Not financial advice.',
};
