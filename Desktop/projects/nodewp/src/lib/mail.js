const nodemailer = require('nodemailer');

const { SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS, MAIL_FROM, MAIL_TO } = process.env;

const transporter = nodemailer.createTransport({
  host: SMTP_HOST,
  port: Number(SMTP_PORT || 587),
  secure: Number(SMTP_PORT) === 465,
  auth: { user: SMTP_USER, pass: SMTP_PASS }
});

function escapeHtml(s='') {
  return String(s).replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
}

async function sendContactMail({ name, email, message, source = 'contact-modal' }) {
  const text = `New contact submission\nFrom: ${name} <${email}>\nSource: ${source}\n\n${message}`;
  const html = `<p><strong>New contact submission</strong></p>
<p><strong>From:</strong> ${escapeHtml(name)} &lt;${escapeHtml(email)}&gt;</p>
<p><strong>Source:</strong> ${escapeHtml(source)}</p>
<pre style="white-space:pre-wrap;font-family:system-ui,Segoe UI,Roboto,Arial,sans-serif">${escapeHtml(message)}</pre>`;
  return transporter.sendMail({
    from: MAIL_FROM,
    to: MAIL_TO,
    subject: `Contact form: ${name}`,
    replyTo: `${name} <${email}>`,
    text, html
  });
}

module.exports = { sendContactMail };
