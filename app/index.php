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
    // --- Configuration (Injected via User Data) ---
    // These variables should be replaced by your actual retrieval logic or env vars in a real app
    // For this demo, we assume variables are set in the environment or passed via include
    
    $db_host = 'YOUR_RDS_ENDPOINT'; // User Data script will sed/replace this
    $db_user = 'admin';             // User Data script will sed/replace this
    $db_pass = 'YOUR_PASSWORD';     // User Data script will sed/replace this
    $db_name = 'fortress_app';

    // --- Database Connection Test ---
    $conn = new mysqli($db_host, $db_user, $db_pass, $db_name);

    if ($conn->connect_error) {
        echo '<div class="status-box failure">';
        echo '<strong>⚠️ Connection Failed:</strong> Database is unreachable.<br>';
        echo '<small>Error: ' . $conn->connect_error . '</small>';
        echo '</div>';
    } else {
        echo '<div class="status-box success">';
        echo '<strong>✅ Secure Connection Established</strong><br>';
        echo 'Connected to RDS via Private Subnet.<br>';
        echo '<small>Database Version: ' . $conn->server_info . '</small>';
        echo '</div>';
    }
    ?>

    <h3>Server Metadata (Internal Only)</h3>
    <div class="server-info">
        <?php
        // Fetch Metadata via IMDSv2
        $token_headers = array('X-aws-ec2-metadata-token-ttl-seconds: 21600');
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, "http://169.254.169.254/latest/api/token");
        curl_setopt($ch, CURLOPT_HTTPHEADER, $token_headers);
        curl_setopt($ch, CURLOPT_CUSTOMREQUEST, "PUT");
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        $token = curl_exec($ch);
        
        if ($token) {
            $meta_headers = array("X-aws-ec2-metadata-token: $token");
            
            function getMeta($path, $headers) {
                $ch = curl_init();
                curl_setopt($ch, CURLOPT_URL, "http://169.254.169.254/latest/meta-data/$path");
                curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
                curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
                return curl_exec($ch);
            }

            $instance_id = getMeta('instance-id', $meta_headers);
            $az = getMeta('placement/availability-zone', $meta_headers);
            $private_ip = getMeta('local-ipv4', $meta_headers);

            echo "Instance ID: " . $instance_id . "<br>";
            echo "Zone: " . $az . "<br>";
            echo "Private IP: " . $private_ip . "<br>";
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