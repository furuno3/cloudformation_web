#!/bin/bash
# ホスト名の設定
hostnamectl set-hostname $HOST_NAME

# 更新とタイムゾーンの設定
dnf update
timedatectl set-timezone Asia/Tokyo

# ロケールの設定
localectl set-locale LANG=ja_JP.UTF-8
localectl set-keymap jp-OADG109A
source /etc/locale.conf

# Telnetのインストール
#dnf -y install telnet

# SSM Agentの設定と起動
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

# Apacheのインストールと設定
dnf -y install httpd
systemctl enable httpd
systemctl start httpd

# .htaccessの設定
sed -i '/<Directory "\/var\/www\/html">/,/<\/Directory>/s/AllowOverride None/AllowOverride All/' /etc/httpd/conf/httpd.conf
systemctl restart httpd

# PHPと拡張モジュールのインストール
#dnf -y install php php-mysqlnd php-gd php-intl php-zip

# MySQLクライアントのインストール
dnf -y localinstall https://dev.mysql.com/get/mysql80-community-release-el9-1.noarch.rpm
rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2023
dnf -y install mysql-community-client

# WordPressをダウンロードしてドキュメントルートに移動
#wget https://ja.wordpress.org/latest-ja.tar.gz
#tar -zxvf latest-ja.tar.gz
#rm latest-ja.tar.gz
#mv wordpress/* /var/www/html
#rmdir wordpress
#chown -R apache:apache /var/www/html
#chmod -R 755 /var/www/html

# WordPressの設定ファイルを作成してデータベース設定を適用
#cd /var/www/html
#sudo -u apache cp wp-config-sample.php wp-config.php
#sed -i "s/database_name_here/${DB_NAME}/" wp-config.php
#sed -i "s/username_here/${DB_MASTER_USER_NAME}/" wp-config.php
#sed -i "s/password_here/${DB_MASTER_USER_PASSWORD}/" wp-config.php
#sed -i "s/localhost/${RDS_ENDPOINT}/" wp-config.php
#chmod 640 wp-config.php

# WP-CLIのインストール
#curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
#chmod +x wp-cli.phar
#mv wp-cli.phar /usr/local/bin/wp

# WP-CLIの設定
#mkdir /usr/share/httpd/.wp-cli
#cat <<EOL > /usr/share/httpd/.wp-cli/config.yml
#apache_modules:
#  - mod_rewrite
#EOL

# WordPressのインストール
#EC2_PUBLIC_IP=$(ec2-metadata --public-ipv4 | cut -d ' ' -f 2)
#sudo -u apache wp core install --url="http://${EC2_PUBLIC_IP}" --title="${WP_TITLE}" --admin_user="${WP_USER_NAME}" --admin_password="${WP_USER_PASSWORD}" --admin_email="${WP_USER_EMAIL}" --skip-email
#systemctl restart httpd

# .htaccessの設定
#sudo -u apache wp option update permalink_structure '/%postname%/'
#sudo -u apache wp rewrite flush --hard

# rsyslogのインストールと設定
dnf -y install rsyslog
chmod 644 /var/log/messages
systemctl enable rsyslog
systemctl start rsyslog

# collectdのインストール
dnf -y install collectd

# CloudWatch Agentのインストールと設定
dnf -y install amazon-cloudwatch-agent
systemctl enable amazon-cloudwatch-agent

# CloudWatch Agentの設定ファイルを作成
cat <<EOL > /opt/aws/amazon-cloudwatch-agent/bin/config.json
{
        "agent": {
                "metrics_collection_interval": 60,
                "run_as_user": "cwagent"
        },
        "logs": {
                "logs_collected": {
                        "files": {
                                "collect_list": [
                                        {
                                                "file_path": "/var/log/messages",
                                                "log_group_class": "STANDARD",
                                                "log_group_name": "messages",
                                                "log_stream_name": "{instance_id}",
                                                "retention_in_days": -1
                                        }
                                ]
                        }
                }
        },
        "metrics": {
                "aggregation_dimensions": [
                        [
                                "InstanceId"
                        ]
                ],
                "append_dimensions": {
                        "AutoScalingGroupName": "\${!aws:AutoScalingGroupName}",
                        "ImageId": "\${!aws:ImageId}",
                        "InstanceId": "\${!aws:InstanceId}",
                        "InstanceType": "\${!aws:InstanceType}"
                },
                "metrics_collected": {
                        "collectd": {
                                "metrics_aggregation_interval": 60
                        },
                        "disk": {
                                "measurement": [
                                        "used_percent"
                                ],
                                "metrics_collection_interval": 60,
                                "resources": [
                                        "*"
                                ]
                        },
                        "mem": {
                                "measurement": [
                                        "mem_used_percent"
                                ],
                                "metrics_collection_interval": 60
                        },
                        "statsd": {
                                "metrics_aggregation_interval": 60,
                                "metrics_collection_interval": 10,
                                "service_address": ":8125"
                        }
                }
        }
}
EOL
chmod 600 /opt/aws/amazon-cloudwatch-agent/bin/config.json
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json -s

# 再起動
shutdown -r now
