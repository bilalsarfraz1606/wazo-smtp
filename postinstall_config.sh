#!/bin/bash

TARGET_DIR="/etc/xivo/custom-templates/postfix/etc/postfix"
MAIN_CF_SOURCE="/usr/share/xivo-config/templates/mail/etc/postfix/main.cf"
MAIN_CF_DEST="$TARGET_DIR/main.cf"
WEBHOOK_CONFIG="/etc/wazo-webhookd/conf.d/40-whitelabel.yml"

echo "🔧 Creating directory structure..."
mkdir -p "$TARGET_DIR" || { echo "❌ Failed to create directory: $TARGET_DIR"; exit 1; }

echo "📝 Creating sender_relay file..."
echo "notifications@channelpbx.com smtp.office365.com:587" > "$TARGET_DIR/sender_relay" || { echo "❌ Failed to create sender_relay"; exit 1; }

echo "🔐 Creating sasl_passwd file..."
echo "smtp.office365.com:587 notifications@channelpbx.com:qpx-rgt7FAU.xwg3afj" > "$TARGET_DIR/sasl_passwd" || { echo "❌ Failed to create sasl_passwd"; exit 1; }

echo "🔒 Setting permissions for sasl_passwd..."
chmod 600 "$TARGET_DIR/sasl_passwd" || { echo "❌ chmod failed"; exit 1; }
chown root:root "$TARGET_DIR/sasl_passwd" || { echo "❌ chown failed"; exit 1; }

echo "📋 Copying main.cf..."
cp "$MAIN_CF_SOURCE" "$MAIN_CF_DEST" || { echo "❌ Failed to copy main.cf"; exit 1; }

echo "➕ Appending smtp_tls_security_level to main.cf..."
echo "smtp_tls_security_level = encrypt" >> "$MAIN_CF_DEST" || { echo "❌ Failed to append to main.cf"; exit 1; }

echo "🔁 Running postmap..."
cd "$TARGET_DIR" || { echo "❌ Failed to cd into $TARGET_DIR"; exit 1; }

which postmap > /dev/null || { echo "❌ postmap not found. Install postfix first."; exit 1; }

postmap sasl_passwd || { echo "❌ postmap sasl_passwd failed"; exit 1; }
postmap sender_relay || { echo "❌ postmap sender_relay failed"; exit 1; }

echo "🔄 Running xivo-update-config..."
which xivo-update-config > /dev/null || { echo "❌ xivo-update-config not found"; exit 1; }

xivo-update-config || { echo "❌ xivo-update-config execution failed"; exit 1; }

echo "📦 Creating APNS config file for Wazo mobile push..."
mkdir -p "$(dirname "$WEBHOOK_CONFIG")"
cat > "$WEBHOOK_CONFIG" <<EOF
mobile_apns_call_topic: com.commschannel.channelpbx.voip
mobile_apns_default_topic: com.commschannel.channelpbx
EOF

echo "✅ All steps completed successfully."
