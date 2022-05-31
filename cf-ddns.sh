#!/bin/bash


# wget -qO /usr/local/bin/cf-ddns.sh https://moththe.com/posts/cf_ddns/cf-ddns.sh


#1 �޸Ľű��� auth_email,auth_key,zone_name,record_name ��Ӧ����Ϊ�Լ�����Ϣ
#2 ���ű�ִ��Ȩ�� chmod +x /usr/local/bin/cf-ddns.sh
#3 ִ�� crontab -e ��������¶�ʱ����*/1 * * * * /usr/local/bin/cf-ddns.sh >/dev/null 2>&1
#4 ��ô��ȡ�ҵ�Cloudflare API�� ���� https://www.cloudflare.com/a/account/my-account �����Ϸ�ѡ�� API Tokens ��ǩҳ��Ȼ��鿴ҳ���·��� Global API Key
#���У��� auth_email ������ CloudFlare �˺ŵ����䣬�� auth_key ����ǰ���ȡ�� API��zone_name �������� zhaozhuji.net��record_name ���� DDNS ������ ddns.zhaozhuji.net��



# CHANGE THESE
auth_email="user@example.com"
auth_key="c2547eb745079dac9320b638f5e225cf483cc5cfdda41" # found in cloudflare account settings
zone_name="example.com"
record_name="www.example.com"

# MAYBE CHANGE THESE
ip=$(curl -s http://ipv4.icanhazip.com)
ip_file="ip.txt"
id_file="cloudflare.ids"
log_file="cloudflare.log"

# LOGGER
log() {
    if [ "$1" ]; then
        echo -e "[$(date)] - $1" >> $log_file
    fi
}

# SCRIPT START
log "Check Initiated"

if [ -f $ip_file ]; then
    old_ip=$(cat $ip_file)
    if [ $ip == $old_ip ]; then
        echo "IP has not changed."
        exit 0
    fi
fi

if [ -f $id_file ] && [ $(wc -l $id_file | cut -d " " -f 1) == 2 ]; then
    zone_identifier=$(head -1 $id_file)
    record_identifier=$(tail -1 $id_file)
else
    zone_identifier=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$zone_name" -H "X-Auth-Email: $auth_email" -H "X-Auth-Key: $auth_key" -H "Content-Type: application/json" | grep -Po '(?<="id":")[^"]*' | head -1 )
    record_identifier=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records?name=$record_name" -H "X-Auth-Email: $auth_email" -H "X-Auth-Key: $auth_key" -H "Content-Type: application/json"  | grep -Po '(?<="id":")[^"]*')
    echo "$zone_identifier" > $id_file
    echo "$record_identifier" >> $id_file
fi

update=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records/$record_identifier" -H "X-Auth-Email: $auth_email" -H "X-Auth-Key: $auth_key" -H "Content-Type: application/json" --data "{\"id\":\"$zone_identifier\",\"type\":\"A\",\"name\":\"$record_name\",\"content\":\"$ip\"}")

if [[ $update == *"\"success\":false"* ]]; then
    message="API UPDATE FAILED. DUMPING RESULTS:\n$update"
    log "$message"
    echo -e "$message"
    exit 1 
else
    message="IP changed to: $ip"
    echo "$ip" > $ip_file
    log "$message"
    echo "$message"
fi