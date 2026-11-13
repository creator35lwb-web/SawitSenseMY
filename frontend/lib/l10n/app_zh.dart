// Simplified Chinese (简体中文) strings for SawitSense.
//
// Drafted by SS (Claude Code), Sep 2026, for a native reader to review (D10).
// Uses the terms Malaysian Chinese readers see in the press: 原棕油 (CPO),
// 鲜果串 (FFB), 出油率 (OER), and 北马 / 中马 / 南马 for the peninsular regions.
const Map<String, String> zhStrings = {
  // App
  'app_title': 'SawitSense MY',
  'app_tagline': 'Sawit Kita, Harga Kita',
  'app_subtitle': '原棕油价格追踪与出油率信号',

  // Navigation
  'nav_dashboard': '价格总览',
  'nav_calculator': '公平价格',
  'nav_history': '历史价格',
  'nav_journal': '我的销售',

  // Dashboard
  'dashboard_title': '每日价格总览',
  'cpo_spot_price': '原棕油现货价',
  'ffb_reference': '鲜果串参考价（1% 出油率）',
  'per_tonne': '/公吨',
  'per_1pct': '/1% 出油率',
  'source': '来源',

  // 数据新鲜度（伦理框架：绿 <6 小时，黄 6-12 小时，红 >12 小时）
  'freshness_green': '最新',
  'freshness_amber': '稍旧',
  'freshness_red': '已过时',
  'freshness_hint': '与收购商的报价比较前，请先核对日期。',
  'no_data': '暂无价格数据',
  'prices_unavailable': '目前无法加载价格。请检查网络连接，然后重试。',
  'retry': '重试',

  // 估算模式横幅（路径 C，见 ADR-001）
  'indicative_banner_headline': '估算价 — 并非 MPOB 官方鲜果串参考价',
  'indicative_banner_body':
      'MPOB 已将每日鲜果串参考价移至执照持有人登录页面。在恢复公开之前，'
      '这里显示的各地区价格，是根据 MPOC 每日原棕油结算价和 MPOB 每月出油率推算出来的。'
      '仅供参考，不能作为法定基准。',
  'indicative_banner_learn_more': '了解更多（ADR-001）',
  'indicative_chip': '估算',

  // MPOB 每日鲜果串参考价，厂门价（D22）
  'ffb_official_source': 'MPOB 每日参考价，{date}',
  'source_mpob': 'MPOB 厂门价',
  'note_miri_bintulu': '美里和民都鲁',
  'dealer_note': 'MPOB 的价格是厂门价。收购商通常会付得低一些，以支付运输费和他们的利润。',
  'method_link_official': '这些价格从哪里来？',
  'method_title_official': '这些价格的来源',
  'method_official_step1_title': 'MPOB 每日参考价',
  'method_official_step1_body':
      'MPOB 在每个交易日公布各地区每 1% 出油率的厂门价。SawitSense 照 MPOB 公布的价格显示。',
  'method_official_timing': 'MPOB 在交易日约中午 12 点公布价格。星期六、星期日和公共假期没有新价格，'
      '因此 SawitSense 会显示上一个交易日的价格及其日期。',
  'method_sarawak_note': 'MPOB 的砂拉越价格适用于美里和民都鲁。',

  // 价格计算方法（说明页），附上可供核对的链接
  'method_link': '这是怎么计算的？',
  'method_title': '这些价格是怎么计算的',
  'method_step1_title': '每 1% 出油率的价格（估算）',
  'method_step1_same': '所有地区都一样，因为它来自同一个全国原棕油价格。',
  'method_cpo_source': '原棕油价格：MPOC 每日棕油价格',
  'method_factor_source': '0.93：SawitSense 公开记录的估算系数（ADR-001）',
  'method_step2_title': '各地区平均出油率（MPOB）',
  'method_step2_note':
      '您自己的出油率，是收购商或油厂为您评定的。这里列出的是 MPOB 公布的各地区平均值。',
  'method_oer_source': '出油率：MPOB Prestasi Sawit',
  'method_oer_source_month': '出油率：MPOB Prestasi Sawit（请选择 {month}）',
  'method_step3_title': '您的公平价格',
  'method_step3_body':
      '每 1% 出油率的价格 × 您的评定出油率 = 每公吨公平价格。'
      '可以用“公平价格”计算器算出来。',
  'method_official_note':
      'MPOB 官方鲜果串参考价须以 MPOB 执照持有人身份登录才能查看，所以无法公开链接。'
      '这就是这些价格只是估算价的原因。',
  'open_data': '开放数据：SawitSense 发布过的所有价格',
  'region_north': '北马',
  'region_south': '南马',
  'region_central': '中马',
  'region_east_coast': '东海岸',
  'region_sabah': '沙巴',
  'region_sarawak': '砂拉越',

  // Calculator
  'calc_title': '公平价格计算器',
  'calc_subtitle': '公式：每公吨价格 = 每 1% 出油率价格 × 评定出油率%',
  'calc_region': '选择地区',
  'calc_price_1pct': '每 1% 出油率价格（RM）',
  'calc_oer': '评定出油率（%）',
  'oer': '出油率',
  'calc_paid': '实收价格（RM/公吨）— 选填',
  'calc_calculate': '计算',
  'calc_fair_price': '公平价格',
  'calc_verdict': '评估结果',
  'calc_gap': '差距',
  'calc_mill_gate_value': '您的果串在厂门的价值（MPOB）',
  'calc_oer_step': '按此价格，出油率每 0.25% 值每公吨 RM {rm}。',
  'calc_target_title': '议价目标',
  'calc_target': '每公吨 RM {rm} 或以上',
  'calc_target_note': '与上方价格相差 {pct}% 以内，为收购商留出运输费和利润的空间。'
      '这是 SawitSense 的参考，并非 MPOB 的数字。',
  'calc_short_of_target': '每公吨再多 RM {rm} 即可达到目标。',
  'calc_transport': '另扣运输费（RM/公吨）',
  'calc_transport_tip': '选填。只有收购商从上面的价格再扣运输费时才填。价格已包含运输费就留空。',
  'calc_net_price': 'RM {paid} 扣 RM {transport} 运输费 = RM {net}/公吨',
  'calc_pays_for': '这个价格相当于 {oer}% 出油率',
  'calc_pays_for_avg': '{region}油厂平均出油率 {avg}%（MPOB，{month}）',
  'calc_pays_for_note': '用这个数字比较不同的报价：越高越好。它不受收购商所报出油率的影响。',
  'guide_link': '接受价格之前：4 项检查',
  'guide_title': '接受价格之前',
  'guide_intro': '以下四项检查，来自一位小园主一个月的收据：共 23 次交易，卖给五家收购商。',
  'guide_1_title': '价格里包含运输费吗？',
  'guide_1_body':
      '有些收购商报价后再扣运输费，有些报价已包含运输费。例如：每公吨 RM 790 扣除 RM 25 '
      '运输费后是 RM 765，比已包含运输费的 RM 770 还低。先问清楚，再把运输费填入计算器，'
      '这样比较的就是您实际拿到的价格。',
  'guide_2_title': '收购商说的出油率只是报价',
  'guide_2_body':
      '在那些收据里，每家收购商每一车都写同一个出油率，例如 18%。那是收购商的报价，'
      '不是对果串的测定。出油率写得低，同样的价格看起来就更接近 MPOB 的价格。'
      '所以要比较每公吨的价格，或者计算器显示的“相当于多少出油率”。',
  'guide_3_title': '同一天多问一家收购商',
  'guide_3_body': '同一天，两家收购商的价格相差可达每公吨 RM 40。一车 5 公吨就是 RM 200。',
  'guide_4_title': '留意 MPOB 的价格有没有变动',
  'guide_4_body':
      '收购商的价格每次调整 RM 10，而且比 MPOB 的价格慢：那个月 MPOB 的价格上涨了，'
      '收购商的价格却几乎没变。“历史价格”页显示 MPOB 过去 30 天的价格。'
      '如果 MPOB 的价格已经上涨，而您的收购商还没调，可以要求更高的价格。',
  'guide_limits':
      '这只是一位小园主一个月的情况。各地、各家收购商都不同；SawitSense '
      '没有找到任何关于收购商应付多少的官方数字。',
  'journal_title': '我的销售记录',
  'journal_privacy':
      '您的销售记录只保存在这部手机的这个浏览器里。SawitSense 看不到，'
      '也不会发送到任何地方。请不时导出一份备份：清除浏览器数据会把记录删掉。',
  'journal_not_kept': '这个浏览器没有保存记录（无痕窗口，或存储被禁用）。关闭页面前请先导出一份。',
  'journal_empty': '还没有销售记录。添加一笔，就能看到它的价格与当天 MPOB 价格的比较。',
  'journal_add': '添加一笔销售',
  'journal_date': '销售日期',
  'journal_tonnes': '重量（公吨）',
  'journal_price': '价格（RM/公吨）',
  'journal_oer': '收据上的出油率（%）',
  'journal_oer_tip': '选填。收购商写的出油率（如有）。',
  'journal_label': '收购商',
  'journal_label_tip': '选填。为每家收购商选一个字母。不保存任何名字。',
  'journal_dealer': '收购商 {label}',
  'journal_save': '保存',
  'journal_cancel': '取消',
  'journal_summary_title': '全部销售',
  'journal_summary_received': '实收：RM {rm}',
  'journal_summary_count': '销售 {n} 笔 · {t} 公吨',
  'journal_summary_average': '平均实收：每公吨 RM {rm}',
  'journal_summary_pays_for': '您的价格平均相当于 {oer}% 出油率',
  'journal_month_total': '销售 {n} 笔 · {t} 公吨 · RM {rm}',
  'journal_sale_sum': '{t} 公吨 × RM {kept} = RM {total}',
  'journal_sale_pays_for': '相当于 {oer}% 出油率（MPOB {date} 价格 {price}）',
  'journal_sale_below': '按 {oer}% 出油率，比厂门价值低 RM {rm}（{pct}%）',
  'journal_sale_above': '按 {oer}% 出油率，比厂门价值高 RM {rm}（{pct}%）',
  'journal_sale_no_mpob': '应用里没有那一天的 MPOB 价格，所以这笔销售无法比较。',
  'journal_delete': '删除',
  'journal_delete_confirm': '删除这笔销售？',
  'journal_delete_all': '全部删除',
  'journal_delete_all_confirm':
      '从这部手机删除全部 {n} 笔销售？此操作无法撤销。想保留的话，请先导出一份。',
  'journal_export': '导出',
  'journal_import': '导入',
  'journal_exported': '已保存为 {file}（销售 {n} 笔）。',
  'journal_export_failed': '无法在这部设备上保存文件。',
  'journal_imported': '已添加 {n} 笔销售。略过 {s} 笔（已存在，或无法读取）。',
  'journal_import_failed': '无法把这个文件读成 SawitSense 的销售记录。',
  'journal_file_note':
      '导出会保存一个 CSV 文件，可用 Excel 或 Google Sheets 打开。文件留在您保存的地方，'
      'SawitSense 不会收到。导入则是在这部手机上把这样的文件读回来。',
  'calc_oer_tip': '出油率每差 1%，每公吨差 RM 42 以上',
  'calc_prices_unavailable':
      '无法加载今日价格。请根据您的收据或 MPOB 通告，输入每 1% 出油率的价格。',
  'verdict_green': '公平 — 与基准相差 5% 以内',
  'verdict_amber': '注意 — 低于基准 5-15%',
  'verdict_red': '明显偏低 — 低于基准超过 15%',
  'verdict_badge_green': '绿灯',
  'verdict_badge_amber': '黄灯',
  'verdict_badge_red': '红灯',
  'validation_required': '必填',
  'validation_number': '请输入有效的数字',

  // History
  'history_title': '历史价格',
  'history_series_mpob': 'MPOB 价格',
  'history_series_cpo': '原棕油价格',
  'history_ffb_subtitle': 'MPOB 每日每 1% 出油率的厂门价，最近 30 天',
  'history_col_ffb': '每 1% 出油率',
  'history_col_change': '涨跌',
  'history_ffb_note': 'MPOB 在星期六、星期日和公共假期不公布价格，所以这些日子没有列出。',
  'history_subtitle': '原棕油现货价 30 天走势',
  'history_no_data': '暂无历史数据',
  'history_col_date': '日期',
  'history_col_cpo': '原棕油（RM/公吨）',

  // Feedback
  'feedback_title': '意见反馈',
  'feedback_helpful': '很有帮助！',
  'feedback_confusing': '有些地方看不懂',
  'feedback_wrong': '价格好像不对',
  'share_button': '分享',
  'share_title': '分享 SawitSense MY',
  'share_pitch': 'SawitSense MY：为小园主提供免费的每日棕油价格，支持 BM、English 和中文，'
      '每个数字都附有来源链接。',
  'share_copy_link': '复制链接',
  'share_link_copied': '链接已复制',
  'share_email': '电子邮件',
  'share_email_subject': 'SawitSense MY · 每日棕油价格',
  'feedback_form_note': '将打开一份简短的 Google 表单，无需登录。请勿填写个人资料。',
  'close': '关闭',

  // MPOB 最新消息（D18）
  'mpob_updates_title': 'MPOB 最新消息',
  'mpob_ffb_pdf': '每日鲜果串参考价（PDF）',
  'mpob_news': '棕油新闻',
  'mpob_press': 'MPOB 新闻稿',
  'mpob_links_note': '以上链接为 MPOB 网站，内容为英文和马来文。',

  // Footer
  'footer_open_source': '开源',
  'footer_open_data': '开放数据',
  'footer_github': '在 GitHub 查看',
  'footer_disclaimer': '价格仅供参考，请核对每个价格旁注明的来源。不构成财务建议。',
};
