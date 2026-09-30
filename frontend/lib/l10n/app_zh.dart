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
  'calc_paid': '实收价格（RM/公吨）— 选填',
  'calc_calculate': '计算',
  'calc_fair_price': '公平价格',
  'calc_verdict': '评估结果',
  'calc_gap': '差距',
  'calc_oer_tip': '出油率每差 1%，每公吨差 RM 42 以上',
  'calc_prices_unavailable':
      '无法加载今日价格。请根据您的收据或 MPOB 通告，输入每 1% 出油率的价格。',
  'verdict_green': '公平 — 与 MPOB 基准相差 5% 以内',
  'verdict_amber': '注意 — 低于基准 5-15%',
  'verdict_red': '明显偏低 — 低于基准超过 15%',
  'verdict_badge_green': '绿灯',
  'verdict_badge_amber': '黄灯',
  'verdict_badge_red': '红灯',
  'validation_required': '必填',
  'validation_number': '请输入有效的数字',

  // History
  'history_title': '原棕油历史价格',
  'history_subtitle': '原棕油现货价 30 天走势',
  'history_no_data': '暂无历史数据',
  'history_col_date': '日期',
  'history_col_cpo': '原棕油（RM/公吨）',

  // Feedback
  'feedback_title': '意见反馈',
  'feedback_helpful': '很有帮助！',
  'feedback_confusing': '有些地方看不懂',
  'feedback_wrong': '价格好像不对',
  'feedback_thanks': '谢谢您的反馈！',
  'close': '关闭',

  // Footer
  'footer_open_source': '开源',
  'footer_open_data': '开放数据',
  'footer_github': '在 GitHub 查看',
  'footer_disclaimer': '价格仅供参考，请核对每个价格旁注明的来源。不构成财务建议。',
};
