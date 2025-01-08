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

# rsyslogのインストールと設定
dnf -y install rsyslog
chmod 644 /var/log/messages
systemctl enable rsyslog
systemctl start rsyslog

# collectdのインストール
dnf -y install collectd

# mysqlサーバーをインストール
dnf install mysql-server -y
dnf localinstall https://dev.mysql.com/get/mysql80-community-release-el9-5.noarch.rpm
dnf install mysql-server -y

# mysqlデーモンを起動
systemctl start mysqld
systemctl enable mysqld
systemctl status mysqld

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
