# Wazo SMTP Setup Script

This script sets up Postfix relay configuration for Wazo (XiVO) with Office365 SMTP.

## 🔧 Features
- Creates required directory structure in `/etc/xivo/custom-templates/`
- Adds `sender_relay` and `sasl_passwd`
- Copies and appends to `main.cf`
- Runs `postmap` and `xivo-update-config`

## 🚀 Usage

```bash
wget https://raw.githubusercontent.com/bilalsarfraz1606/wazo-smtp/main/postfix_config.sh
chmod +x postfix_config.sh
sudo ./postfix_config.sh
