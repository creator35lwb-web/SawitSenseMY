// Bahasa Malaysia strings for SawitSense.
const Map<String, String> msStrings = {
  // App
  'app_title': 'SawitSense MY',
  'app_tagline': 'Sawit Kita, Harga Kita',
  'app_subtitle': 'Penjejak Harga CPO & Isyarat OER',

  // Navigation
  'nav_dashboard': 'Papan Pemuka',
  'nav_calculator': 'Harga Adil',
  'nav_history': 'Sejarah Harga',

  // Dashboard
  'dashboard_title': 'Papan Pemuka Harga Harian',
  'cpo_spot_price': 'Harga Semasa CPO',
  'ffb_reference': 'Harga Rujukan BTS (1% OER)',
  'per_tonne': '/tan',
  'per_1pct': '/1% OER',
  'source': 'Sumber',

  // Kesegaran data (rangka kerja etika: HIJAU <6j, AMBAR 6-12j, MERAH >12j)
  'freshness_green': 'Terkini',
  'freshness_amber': 'Agak lama',
  'freshness_red': 'Tidak terkini',
  'freshness_hint': 'Semak tarikh sebelum membandingkan dengan harga peniaga.',
  'no_data': 'Tiada data harga tersedia',
  'prices_unavailable':
      'Harga tidak dapat dimuatkan sekarang. Semak sambungan anda dan cuba lagi.',
  'retry': 'Cuba lagi',

  // Sepanduk mod indikatif (Laluan C — lihat ADR-001)
  'indicative_banner_headline':
      'Harga indikatif — bukan Harga Rujukan BTS rasmi MPOB',
  'indicative_banner_body':
      'MPOB telah mengalihkan Harga Rujukan BTS Harian ke laluan log masuk pelesen. '
      'Sementara dipulihkan, harga wilayah yang dipaparkan diterbitkan daripada harga '
      'penyelesaian CPO harian MPOC dan OER bulanan MPOB. Gunakan sebagai panduan, '
      'bukan penanda aras sah.',
  'indicative_banner_learn_more': 'Ketahui lebih lanjut (ADR-001)',
  'indicative_chip': 'Indikatif',

  // Cara harga dikira (helaian kaedah), dengan pautan untuk menyemaknya
  'method_link': 'Bagaimana ia dikira?',
  'method_title': 'Bagaimana harga ini dikira',
  'method_step1_title': 'Harga per 1% OER (indikatif)',
  'method_step1_same':
      'Sama untuk semua wilayah, kerana ia datang daripada satu harga CPO nasional.',
  'method_cpo_source': 'Harga CPO: Harga Minyak Sawit Harian MPOC',
  'method_factor_source': '0.93: anggaran SawitSense yang didokumenkan (ADR-001)',
  'method_step2_title': 'Purata OER mengikut wilayah (MPOB)',
  'method_step2_note':
      'OER anda sendiri ialah gred yang diberi oleh peniaga atau kilang anda. '
      'Ini ialah purata MPOB bagi setiap wilayah.',
  'method_oer_source': 'OER: MPOB Prestasi Sawit',
  'method_oer_source_month': 'OER: MPOB Prestasi Sawit (pilih {month})',
  'method_step3_title': 'Harga adil anda',
  'method_step3_body':
      'Harga per 1% OER × OER gred anda = harga adil per tan. '
      'Kira dalam kalkulator Harga Adil.',
  'method_official_note':
      'Harga Rujukan BTS rasmi MPOB memerlukan log masuk pelesen MPOB, jadi ia '
      'tidak dapat dipautkan secara umum. Itulah sebabnya harga ini indikatif.',
  'open_data': 'Data terbuka: setiap harga yang telah diterbitkan SawitSense',
  'region_north': 'Utara',
  'region_south': 'Selatan',
  'region_central': 'Tengah',
  'region_east_coast': 'Pantai Timur',
  'region_sabah': 'Sabah',
  'region_sarawak': 'Sarawak',

  // Calculator
  'calc_title': 'Kalkulator Harga Adil',
  'calc_subtitle': 'Formula: Harga/tan = Harga_1% x OER_Gred%',
  'calc_region': 'Pilih Wilayah',
  'calc_price_1pct': 'Harga per 1% OER (RM)',
  'calc_oer': 'OER Gred (%)',
  'oer': 'OER',
  'calc_paid': 'Harga Dibayar (RM/tan) — pilihan',
  'calc_calculate': 'Kira',
  'calc_fair_price': 'Harga Adil',
  'calc_verdict': 'Keputusan',
  'calc_gap': 'Jurang',
  'calc_oer_tip': 'Setiap 1% OER = ~RM 42+/tan perbezaan',
  'calc_prices_unavailable':
      'Harga hari ini tidak dapat dimuatkan. Masukkan harga per 1% OER daripada '
      'resit anda atau notis MPOB.',
  'verdict_green': 'ADIL — dalam 5% penanda aras MPOB',
  'verdict_amber': 'BERHATI-HATI — 5-15% di bawah penanda aras',
  'verdict_red': 'DI BAWAH ADIL — lebih 15% di bawah penanda aras',
  'verdict_badge_green': 'HIJAU',
  'verdict_badge_amber': 'AMBAR',
  'verdict_badge_red': 'MERAH',
  'validation_required': 'Wajib diisi',
  'validation_number': 'Nombor tidak sah',

  // History
  'history_title': 'Sejarah Harga CPO',
  'history_subtitle': 'Trend harga semasa CPO 30 hari',
  'history_no_data': 'Tiada data sejarah tersedia lagi',
  'history_col_date': 'Tarikh',
  'history_col_cpo': 'CPO (RM/tan)',

  // Feedback
  'feedback_title': 'Maklum Balas',
  'feedback_helpful': 'Ini berguna!',
  'feedback_confusing': 'Sesuatu mengelirukan',
  'feedback_wrong': 'Harga nampak salah',
  'feedback_thanks': 'Terima kasih atas maklum balas anda!',
  'close': 'Tutup',

  // Footer
  'footer_open_source': 'Sumber Terbuka',
  'footer_open_data': 'Data terbuka',
  'footer_github': 'Lihat di GitHub',
  'footer_disclaimer':
      'Harga untuk rujukan sahaja; semak sumber yang ditunjukkan bersama setiap '
      'harga. Bukan nasihat kewangan.',
};
