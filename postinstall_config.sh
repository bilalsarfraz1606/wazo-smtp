#!/bin/bash

TARGET_DIR="/etc/xivo/custom-templates/postfix/etc/postfix"
MAIN_CF_SOURCE="/usr/share/xivo-config/templates/mail/etc/postfix/main.cf"
MAIN_CF_DEST="$TARGET_DIR/main.cf"
WEBHOOK_CONFIG="/etc/wazo-webhookd/conf.d/40-whitelabel.yml"
CALLERID_FILE="/etc/xivo/asterisk/xivo_in_callerid.conf"

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

echo "📦 Configuring main.cf for Office365 relay..."
cat >> "$MAIN_CF_DEST" <<EOF

# Relay configuration
relayhost = [smtp.office365.com]:587
smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_sasl_security_options = noanonymous
smtp_tls_security_level = encrypt
smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt
sender_dependent_relayhost_maps = hash:/etc/postfix/sender_relay
smtp_sender_dependent_authentication = yes
EOF

echo "🔁 Running postmap..."
cd "$TARGET_DIR" || exit 1
postmap sasl_passwd || exit 1
postmap sender_relay || exit 1

echo "🔄 Updating config with xivo-update-config..."
xivo-update-config || exit 1

echo "📄 Copying hashed maps to /etc/postfix for active config..."
cp "$TARGET_DIR/sasl_passwd" /etc/postfix/sasl_passwd
cp "$TARGET_DIR/sasl_passwd.db" /etc/postfix/sasl_passwd.db
cp "$TARGET_DIR/sender_relay" /etc/postfix/sender_relay
cp "$TARGET_DIR/sender_relay.db" /etc/postfix/sender_relay.db

echo "📦 Writing APNS config..."
mkdir -p "$(dirname "$WEBHOOK_CONFIG")"
cat > "$WEBHOOK_CONFIG" <<EOF
mobile_apns_call_topic: com.commschannel.channelpbx.voip
mobile_apns_default_topic: com.commschannel.channelpbx
EOF

echo "🔁 Restarting wazo-webhookd..."
systemctl restart wazo-webhookd || { echo "❌ Failed to restart wazo-webhookd"; exit 1; }

echo "🛠️ Modifying $CALLERID_FILE..."
if grep -q "^\[international3\]" "$CALLERID_FILE"; then
  sed -i '/^\[international3\]/,/^\[/ s/^add *=.*/add =/' "$CALLERID_FILE"
  echo "✅ Updated 'add' line in [international3] section."
else
  echo "⚠️ [international3] section not found in $CALLERID_FILE"
fi

echo "✅ Postfix + APNS + CallerID config completed successfully."
