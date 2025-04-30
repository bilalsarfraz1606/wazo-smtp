#!/bin/bash

TARGET_DIR="/etc/xivo/custom-templates/postfix/etc/postfix"
MAIN_CF_SOURCE="/usr/share/xivo-config/templates/mail/etc/postfix/main.cf"
MAIN_CF_DEST="$TARGET_DIR/main.cf"
WEBHOOK_CONFIG="/etc/wazo-webhookd/conf.d/40-whitelabel.yml"

echo "🔧 Creating directory structure..."
mkdir -p "$TARGET_DIR" || { echo "❌ Failed to create directory: $TARGET_DIR"; exit 1; }

echo "📝 Creating sender_relay file..."
echo "notifications@channelpbx.com smtp.office365.com:587" > "$TARGET_DIR/sender_relay" || exit 1

echo "🔐 Creating sasl_passwd file..."
echo "smtp.office365.com:587 notifications@channelpbx.com:qpx-rgt7FAU.xwg3afj" > "$TARGET_DIR/sasl_passwd" || exit 1

echo "🔒 Setting permissions..."
chmod 600 "$TARGET_DIR/sasl_passwd" || exit 1
chown root:root "$TARGET_DIR/sasl_passwd" || exit 1

echo "📋 Copying main.cf..."
cp "$MAIN_CF_SOURCE" "$MAIN_CF_DEST" || exit 1

echo "➕ Appending smtp_tls_security_level..."
echo "smtp_tls_security_level = encrypt" >> "$MAIN_CF_DEST"

echo "🔁 Running postmap..."
cd "$TARGET_DIR" || exit 1
postmap sasl_passwd || exit 1
postmap sender_relay || exit 1

echo "🔄 Updating config with xivo-update-config..."
xivo-update-config || exit 1

echo "📦 Writing APNS config..."
mkdir -p "$(dirname "$WEBHOOK_CONFIG")"
cat > "$WEBHOOK_CONFIG" <<EOF
mobile_apns_call_topic: com.commschannel.channelpbx.voip
mobile_apns_default_topic: com.commschannel.channelpbx
EOF

echo "🔁 Restarting wazo-webhookd..."
systemctl restart wazo-webhookd || { echo "❌ Failed to restart wazo-webhookd"; exit 1; }

echo "✅ Postfix + APNS setup completed successfully."
