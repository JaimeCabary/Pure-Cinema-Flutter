import logging
import httpx
from app.config import settings

logger = logging.getLogger(__name__)

class EmailService:
    @staticmethod
    async def send_otp_email(to_email: str, code: str, purpose: str = "login") -> bool:
        """
        Sends an HTML verification OTP email using Resend REST API.
        """
        api_key = settings.RESEND_API_KEY
        if not api_key:
            logger.warning("RESEND_API_KEY not configured. Skipping email dispatch.")
            return False

        purpose_label = "Account Verification" if purpose == "register" else ("Password Reset" if purpose == "reset_password" else "Security Sign In")
        
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

        payload = {
            "from": settings.RESEND_FROM_EMAIL,
            "to": [to_email],
            "subject": f"Your Pure Cinema Verification Code: {code}",
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
                    logger.info(f"Successfully dispatched OTP email to {to_email} via Resend. ID: {res.json().get('id')}")
                    return True
                else:
                    logger.error(f"Resend error: {res.status_code} - {res.text}")
                    return False
        except Exception as e:
            logger.error(f"Failed to send email via Resend: {e}")
            return False
