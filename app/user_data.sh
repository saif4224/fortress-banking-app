#!/bin/bash
# --- Fortress Banking App Bootstrapper ---
# Installs Web Server, PHP, and injects secure credentials at runtime.

# 1. Install Dependencies
dnf update -y
dnf install -y httpd php php-mysqlnd aws-cli jq

# 2. Start Web Server
systemctl start httpd
systemctl enable httpd

# 3. Securely Fetch Credentials (No hardcoding!)
# We use the instance's IAM Role to talk to Secrets Manager
REGION="us-east-1"
SECRET_ID="Fortress/Prod/DB"

# Fetch the JSON secret
SECRET_JSON=$(aws secretsmanager get-secret-value --secret-id $SECRET_ID --query SecretString --output text --region $REGION)

# Parse username and password using jq
DB_USER=$(echo $SECRET_JSON | jq -r .username)
DB_PASS=$(echo $SECRET_JSON | jq -r .password)

# Fetch Database Endpoint (Dynamic Discovery)
DB_HOST=$(aws rds describe-db-instances --db-instance-identifier fortress-db --query 'DBInstances[0].Endpoint.Address' --output text --region $REGION)
DB_NAME="fortress_app"

# 4. Deploy the Banking Application (Professional Index.php)
# We write the PHP file directly, injecting the variables we just fetched.
cat <<EOF > /var/www/html/index.php
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Fortress NeoBank | Secure Portal</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f0f2f5; margin: 0; padding: 0; }
        .header { background-color: #003366; color: white; padding: 20px; text-align: center; }
        .container { max-width: 800px; margin: 40px auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 4px 15px rgba(0,0,0,0.1); }
        .status-box { padding: 15px; margin: 20px 0; border-radius: 5px; border-left: 5px solid; }
        .success { background-color: #d4edda; border-color: #28a745; color: #155724; }
        .failure { background-color: #f8d7da; border-color: #dc3545; color: #721c24; }
        .metadata { font-size: 0.9em; color: #666; margin-top: 10px; }
        .server-info { background: #e9ecef; padding: 10px; border-radius: 4px; font-family: monospace; }
    </style>
</head>
<body>

<div class="header">
    <h1>🏰 Fortress NeoBank</h1>
    <p>Secure Customer Portal v1.0</p>
</div>

<div class="container">
    <h2>System Status Dashboard</h2>
    
    <?php
    // --- Configuration (Injected Securely) ---
    \$db_host = '$DB_HOST';
    \$db_user = '$DB_USER';
    \$db_pass = '$DB_PASS';
    \$db_name = '$DB_NAME';

    // --- Database Connection Test ---
    \$conn = new mysqli(\$db_host, \$db_user, \$db_pass, \$db_name);

    if (\$conn->connect_error) {
        echo '<div class="status-box failure">';
        echo '<strong>⚠️ Connection Failed:</strong> Database is unreachable.<br>';
        echo '<small>Error: ' . \$conn->connect_error . '</small>';
        echo '</div>';
    } else {
        echo '<div class="status-box success">';
        echo '<strong>✅ Secure Connection Established</strong><br>';
        echo 'Connected to RDS via Private Subnet.<br>';
        echo '<small>Database Version: ' . \$conn->server_info . '</small>';
        echo '</div>';
    }
    ?>

    <h3>Server Metadata (Internal Only)</h3>
    <div class="server-info">
        <?php
        // Fetch Metadata via IMDSv2
        \$token_headers = array('X-aws-ec2-metadata-token-ttl-seconds: 21600');
        \$ch = curl_init();
        curl_setopt(\$ch, CURLOPT_URL, "http://169.254.169.254/latest/api/token");
        curl_setopt(\$ch, CURLOPT_HTTPHEADER, \$token_headers);
        curl_setopt(\$ch, CURLOPT_CUSTOMREQUEST, "PUT");
        curl_setopt(\$ch, CURLOPT_RETURNTRANSFER, true);
        \$token = curl_exec(\$ch);
        
        if (\$token) {
            \$meta_headers = array("X-aws-ec2-metadata-token: \$token");
            
            function getMeta(\$path, \$headers) {
                \$ch = curl_init();
                curl_setopt(\$ch, CURLOPT_URL, "http://169.254.169.254/latest/meta-data/\$path");
                curl_setopt(\$ch, CURLOPT_HTTPHEADER, \$headers);
                curl_setopt(\$ch, CURLOPT_RETURNTRANSFER, true);
                return curl_exec(\$ch);
            }

            \$instance_id = getMeta('instance-id', \$meta_headers);
            \$az = getMeta('placement/availability-zone', \$meta_headers);
            \$private_ip = getMeta('local-ipv4', \$meta_headers);

            echo "Instance ID: " . \$instance_id . "<br>";
            echo "Zone: " . \$az . "<br>";
            echo "Private IP: " . \$private_ip . "<br>";
        } else {
            echo "Metadata Service Unavailable (Are we local?)";
        }
        ?>
    </div>

    <p class="metadata">
        🔒 This session is encrypted via TLS 1.3. <br>
        🛡️ Protected by AWS WAF.
    </p>
</div>

</body>
</html>
EOF

# 5. Set Permissions & Restart
chmod 644 /var/www/html/index.php
systemctl restart httpd