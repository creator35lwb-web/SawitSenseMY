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

  // Harga panduan harian BTS MPOB, di pintu kilang (D22)
  'ffb_official_source': 'Harga panduan harian MPOB, {date}',
  'source_mpob': 'MPOB, di pintu kilang',
  'note_miri_bintulu': 'Miri dan Bintulu',
  'dealer_note':
      'Harga MPOB ialah harga di pintu kilang. Peniaga biasanya membayar kurang, '
      'untuk menampung kos pengangkutan dan margin mereka.',
  'method_link_official': 'Dari mana harga ini?',
  'method_title_official': 'Dari mana harga ini datang',
  'method_official_step1_title': 'Harga panduan harian MPOB',
  'method_official_step1_body':
      'MPOB menerbitkan harga bagi setiap 1% OER untuk setiap wilayah pada setiap '
      'hari dagangan, di pintu kilang. SawitSense memaparkannya seperti yang '
      'diterbitkan oleh MPOB.',
  'method_official_timing':
      'MPOB menerbitkan harga sekitar tengah hari pada hari dagangan. Tiada harga '
      'baharu pada hari Sabtu, Ahad atau cuti umum, jadi SawitSense memaparkan '
      'harga hari dagangan terakhir, bersama tarikhnya.',
  'method_sarawak_note': 'Harga Sarawak MPOB adalah untuk Miri dan Bintulu.',

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
  'calc_mill_gate_value': 'Nilai buah anda di pintu kilang (MPOB)',
  'calc_oer_step': 'Setiap 0.25% OER bernilai RM {rm} setan pada harga ini.',
  'calc_target_title': 'Sasaran untuk dirunding',
  'calc_target': 'RM {rm} setan atau lebih',
  'calc_target_note':
      'Dalam lingkungan {pct}% daripada harga di atas, yang memberi ruang kepada '
      'peniaga untuk kos pengangkutan dan margin. Ini panduan SawitSense, '
      'bukan angka MPOB.',
  'calc_short_of_target': 'Tambahan RM {rm} setan akan mencapai sasaran.',
  'calc_oer_tip': 'Setiap 1% OER = ~RM 42+/tan perbezaan',
  'calc_prices_unavailable':
      'Harga hari ini tidak dapat dimuatkan. Masukkan harga per 1% OER daripada '
      'resit anda atau notis MPOB.',
  'verdict_green': 'ADIL — dalam 5% penanda aras',
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
  'share_button': 'Kongsi',
  'share_title': 'Kongsi SawitSense MY',
  'share_pitch':
      'SawitSense MY: harga sawit harian percuma untuk pekebun kecil, dalam BM, '
      'English dan 中文. Setiap angka dipautkan kepada sumbernya.',
  'share_copy_link': 'Salin pautan',
  'share_link_copied': 'Pautan disalin',
  'share_email': 'E-mel',
  'share_email_subject': 'SawitSense MY · harga sawit harian',
  'feedback_form_note':
      'Membuka Borang Google yang ringkas. Tidak perlu log masuk; jangan '
      'sertakan butiran peribadi.',
  'close': 'Tutup',

  // Terkini daripada MPOB (D18)
  'mpob_updates_title': 'Terkini daripada MPOB',
  'mpob_ffb_pdf': 'Harga panduan harian BTS (PDF)',
  'mpob_news': 'Berita sawit',
  'mpob_press': 'Kenyataan media MPOB',
  'mpob_links_note': 'Di laman web MPOB, dalam BM dan bahasa Inggeris.',

  // Footer
  'footer_open_source': 'Sumber Terbuka',
  'footer_open_data': 'Data terbuka',
  'footer_github': 'Lihat di GitHub',
  'footer_disclaimer':
      'Harga untuk rujukan sahaja; semak sumber yang ditunjukkan bersama setiap '
      'harga. Bukan nasihat kewangan.',
};
