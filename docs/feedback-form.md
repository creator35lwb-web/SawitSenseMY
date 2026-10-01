# Feedback form (draft for D14)

The in-app **Feedback** button will open this Google Form, with the reader's choice and the app details already filled in. Alton owns the form, and its responses go to Alton's Google Sheet. **Status:** a draft for Alton to create. The BM and 中文 wording needs a native check.

## Settings

- **Responses → Collect email addresses:** *Do not collect.*
- **Responses → Limit to 1 response:** *Off.* This keeps the form free of any Google sign-in.
- **Responses → Link to Sheets:** *On*, to track feedback over time.
- **Presentation → Confirmation message:** "Terima kasih! Kami membaca setiap maklum balas. · Thank you! We read every response. · 谢谢！我们会阅读每一条反馈。"

## Title and description

**Title:** SawitSense MY · Maklum Balas · Feedback · 意见反馈

**Description:**
- 3 soalan ringkas. Jangan tulis nama, nombor IC atau nombor telefon anda.
- 3 quick questions. Please don't write your name, IC number or phone number.
- 只有 3 个简单问题。请不要填写姓名、身份证号码或电话号码。

## Questions

1. **Rating (1–5 stars, required)**
   - Sejauh mana SawitSense MY berguna kepada anda?
   - How useful is SawitSense MY for you?
   - SawitSense MY 对您有多大帮助？
2. **Multiple choice (required)**
   - **Question:** Maklum balas anda tentang apa? · What is your feedback about? · 您的反馈是关于什么？
   - **Options:**
     - Ini berguna · This is helpful · 很有帮助
     - Sesuatu mengelirukan · Something is confusing · 有些地方看不懂
     - Harga nampak salah · A price looks wrong · 价格好像不对
     - Cadangan · An idea · 建议
     - Lain-lain · Other · 其他
3. **Paragraph (optional)**
   - Ceritakan lebih lanjut (pilihan) · Tell us more (optional) · 请告诉我们更多（选填）
4. **Short answer (optional; filled in by the app)**
   - Butiran aplikasi (diisi secara automatik) · App details (filled in automatically) · 应用信息（自动填写）
   - The app fills in the version, the language and when the prices were updated. For example: `v0.3.10 · zh · prices 2026-10-01 11:01 MYT`. This helps check a "price looks wrong" report against the exact data the reader saw.

## What Alton sends SS

1. In the form, open **⋮ → Get pre-filled link**.
2. Choose "Ini berguna · This is helpful · 很有帮助" and type `APP` in question 4.
3. Click **Get link** and send that link to SS. SS reads the field IDs from it and connects the three options in the app's feedback dialog. The false "Thank you!" message in the app is removed; the form shows its own thank-you.

No personal data is asked for. If Alton later wants to reply to people, an optional contact question can be added, with a line saying what it's used for.
