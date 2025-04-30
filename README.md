# Wazo Config Setup

This repository provides automation scripts to configure:
- Postfix SMTP Relay with Office365
- APNS settings for Wazo Mobile Push
- Caller ID rules update in Asterisk
- (Optional) SSL setup for Wazo with Certbot & Nginx

---

## 🔧 Script 1: `postinstall_config.sh`

This script configures:

- Outbound SMTP relay using Office365
- APNS push topics for iOS calling via Wazo
- Updates `xivo_in_callerid.conf` to adjust international call handling

### 📥 Usage

Run the following commands on your **Debian 11+** Wazo system:

```bash
wget https://raw.githubusercontent.com/bilalsarfraz1606/wazo_config/main/postinstall_config.sh
chmod +x postinstall_config.sh
sudo ./postinstall_config.sh
