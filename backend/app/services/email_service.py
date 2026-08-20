import logging
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import httpx
from app.config import settings

logger = logging.getLogger(__name__)

class EmailService:
    @staticmethod
    def _send_via_google_smtp(to_email: str, subject: str, html_content: str) -> bool:
        """
        Sends an HTML email using Google SMTP (smtp.gmail.com:587 TLS or 465 SSL).
        Requires Google App Password configured in SMTP_USER & SMTP_PASSWORD.
        """
        smtp_user = settings.SMTP_USER.strip() if settings.SMTP_USER else ""
        smtp_pass = settings.SMTP_PASSWORD.replace(" ", "").strip() if settings.SMTP_PASSWORD else ""
        if not smtp_user or not smtp_pass:
            return False

        try:
            msg = MIMEMultipart("alternative")
            msg["Subject"] = subject
            msg["From"] = f"Pure Cinema Security <{smtp_user}>"
            msg["To"] = to_email

            part = MIMEText(html_content, "html")
            msg.attach(part)

            server = smtplib.SMTP(settings.SMTP_SERVER, settings.SMTP_PORT, timeout=10)
            server.ehlo()
            server.starttls()
            server.ehlo()
            server.login(smtp_user, smtp_pass)
            server.sendmail(smtp_user, [to_email], msg.as_string())
            server.quit()
            logger.info(f"Successfully dispatched OTP via Google SMTP to {to_email}")
            return True
        except Exception as e:
            logger.error(f"Google SMTP dispatch error: {e}")
            return False

    @staticmethod
    async def send_otp_email(to_email: str, code: str, purpose: str = "login") -> bool:
        """
        Sends an HTML verification OTP email using Google SMTP or Resend API fallback.
        """
        purpose_label = "Account Verification" if purpose == "register" else ("Password Reset" if purpose == "reset_password" else "Security Sign In")
        subject = f"Your Pure Cinema Security Code: {code}"
        
        html_body = f"""
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <style>
            body {{
              background-color: #050505;
              font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
              color: #ffffff;
              margin: 0;
              padding: 40px 20px;
            }}
            .container {{
              max-width: 520px;
              margin: 0 auto;
              background-color: #0d0d0f;
              border: 1px solid #27272a;
              border-radius: 16px;
              padding: 36px 32px;
              text-align: center;
              box-shadow: 0 10px 30px rgba(0,0,0,0.6);
            }}
            .brand {{
              font-size: 20px;
              font-weight: 900;
              letter-spacing: 5px;
              color: #ffffff;
              text-transform: uppercase;
              margin-bottom: 6px;
            }}
            .tagline {{
              font-size: 10px;
              letter-spacing: 2px;
              color: #71717a;
              text-transform: uppercase;
              margin-bottom: 28px;
            }}
            .title {{
              font-size: 16px;
              font-weight: 700;
              color: #e4e4e7;
              margin-bottom: 12px;
            }}
            .desc {{
              font-size: 13px;
              color: #a1a1aa;
              line-height: 1.5;
              margin-bottom: 28px;
            }}
            .code-box {{
              background-color: #18181b;
              border: 1px solid #3f3f46;
              border-radius: 12px;
              padding: 18px 24px;
              display: inline-block;
              margin-bottom: 28px;
            }}
            .code {{
              font-size: 36px;
              font-weight: 900;
              letter-spacing: 10px;
              color: #ffffff;
              font-family: 'Courier New', Courier, monospace;
            }}
            .footer {{
              font-size: 11px;
              color: #52525b;
              border-top: 1px solid #1f1f23;
              padding-top: 20px;
              line-height: 1.4;
            }}
          </style>
        </head>
        <body>
          <div class="container">
            <div class="brand">PURE CINEMA</div>
            <div class="tagline">Uncompromised 4K Streaming</div>
            
            <div class="title">{purpose_label}</div>
            <div class="desc">Use the one-time verification code below to authorize your session. This code is valid for 10 minutes.</div>
            
            <div class="code-box">
              <div class="code">{code}</div>
            </div>
            
            <div class="footer">
              If you did not request this security code, please ignore this message.<br>
              &copy; 2026 Pure Cinema Studios. All rights reserved.
            </div>
          </div>
        </body>
        </html>
        """

        # 1. Attempt Google SMTP first
        if settings.SMTP_USER and settings.SMTP_PASSWORD:
            smtp_success = EmailService._send_via_google_smtp(to_email, subject, html_body)
            if smtp_success:
                return True

        # 2. Fallback to Resend API
        api_key = settings.RESEND_API_KEY
        if api_key:
            payload = {
                "from": settings.RESEND_FROM_EMAIL,
                "to": [to_email],
                "subject": subject,
                "html": html_body,
            }
            headers = {
                "Authorization": f"Bearer {api_key}",
                "Content-Type": "application/json"
            }
            try:
                async with httpx.AsyncClient(timeout=10.0) as client:
                    res = await client.post("https://api.resend.com/emails", headers=headers, json=payload)
                    if res.status_code in [200, 201]:
                        logger.info(f"Dispatched via Resend API to {to_email}")
                        return True
            except Exception as e:
                logger.error(f"Resend error: {e}")

        logger.info(f"[DEV DISPATCH] Code for {to_email}: {code}")
        return False
