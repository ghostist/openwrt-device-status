#!/bin/sh

#####################################
#
#更新日期2018.1.14
#修改你的SCKEY
#Log文件在 /var/log/server_chan.log 默认保存500条，可修改
#缓存文件在/root/var/ 可修改
#${dir}mac_name文件保存已知设备，格式为【mac 名称】（中间是个空格，不含方括号）
#starttime endtime 脚本运行起止时间
#默认检测时间
#
#####################################
serverchan_sckey=
serverchan_notify_1=1 #外网IP变化
serverchan_notify_2=1 #新设备加入
serverchan_notify_3=1 #设备上下线
serverchan_enable=1
serverchan_enable=${serverchan_enable:-"0"}
hostname=`uci get /etc/config/system.@system[0].hostname`
starttime="800"
endtime="2230"
sleeptime=60
dir="/root/var/"
mkdir -p ${dir}
touch ${dir}lastIPAddress
touch ${dir}mac_name
logfile="/var/log/server_chan.log"
touch ${logfile}
curl -s "http://sc.ftqq.com/$serverchan_sckey.send?text=%e3%80%90${hostname}%e3%80%91%e8%b7%af%e7%94%b1%e9%87%8d%e5%90%af"
echo `date "+%H:%M:%S"` >> ${logfile}
echo "路由重启！" >> ${logfile}

arIpAddress() {
curltest=`which curl`
if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
    wget --no-check-certificate --quiet --output-document=- "http://members.3322.org/dyndns/getip"
else
    curl -k -s "http://members.3322.org/dyndns/getip"
fi
}

lastIPAddress() {
local inter="${dir}lastIPAddress"
cat $inter
}
	
clean_log(){
logrow=$(grep -c "" ${logfile})
if [ $logrow -ge 500 ];then
    cat /dev/null > ${logfile}
    echo "$curtime Log条数超限，清空处理！" >> ${logfile}
fi
}

while [ "$serverchan_enable" = "1" ];
do
serverchan_enable=1
serverchan_enable=${serverchan_enable:-"0"}
curltest=`which curl`
nowtime=`date "+%Y-%m-%d %H:%M:%S"`
if [ -z "$curltest" ] ; then
    wget --no-check-certificate  -q -T 10 http://www.163.com
    [ "$?" == "0" ] && check=200 || check=404
else
    check=`curl -k -s -w "%{http_code}" "http://www.163.com" -o /dev/null`
fi

if [ "$check" == "200" ] ; then
curtime=`date "+%H:%M:%S"`
echo "$curtime online! "
	if [ `date +%k%M` -gt $starttime -a `date +%k%M` -lt $endtime ];then
	clean_log
		#外网IP变化
		if [ "$serverchan_notify_1" = "1" ] ; then
			local hostIP=$(arIpAddress)
			local lastIP=$(lastIPAddress)
			if [ "$lastIP" != "$hostIP" ] && [ ! -z "$hostIP" ] ; then
				sleep ${sleeptime}
				local hostIP=$(arIpAddress)
				local lastIP=$(lastIPAddress)
			fi
			if [ "$lastIP" != "$hostIP" ] && [ ! -z "$hostIP" ] ; then
			    echo "$curtime 【外网IP变化】 当前 IP: ${hostIP}" >> ${logfile}
				echo "$curtime 【外网IP变化】 上次 IP: ${lastIP}" >> ${logfile}
				title="%e3%80%90${hostname}%e3%80%91%e5%a4%96%e7%bd%91IP%e5%9c%b0%e5%9d%80%e5%8f%98%e5%8c%96"
				content="%e5%bd%93%e5%89%8dIP%ef%bc%9a${hostIP}"
				curl -s "http://sc.ftqq.com/$serverchan_sckey.send?text=${title}" -d "&desp=%e6%a3%80%e6%b5%8b%e6%97%b6%e9%97%b4%ef%bc%9a${nowtime}%0D%0A%0D%0A${content}"
				echo "$curtime 【微信推送】 当前IP：${hostIP}" >> ${logfile}
				echo -n $hostIP > ${dir}lastIPAddress
			fi
		fi


		#新设备加入
		if [ "$serverchan_notify_2" = "1" ] ; then
			cat /proc/net/arp | grep -v "^$" | awk '{if($0~"br-lan") print}' | awk -F "[ ]+" '{print $4}' | sort -u > ${dir}tmpfile
			#sed -i '$d' ${dir}tmpfile
			touch ${dir}mac_all
			grep -F -v -f "${dir}mac_all" "${dir}tmpfile" | sort | uniq > ${dir}mac_add
			if [ -s "${dir}mac_add" ] ; then
			    cat ${dir}mac_add >> ${dir}mac_all
			    title="%e3%80%90${hostname}%e3%80%91%e6%96%b0%e8%ae%be%e5%a4%87%e6%8f%90%e9%86%92"
				content=`cat ${dir}mac_add | grep -v "^$" | sed 's/$/ %0D%0A%0D%0A/'`
				curl -s "http://sc.ftqq.com/$serverchan_sckey.send?text=${title}" -d "&desp=%e6%a3%80%e6%b5%8b%e6%97%b6%e9%97%b4%ef%bc%9a${nowtime}%0D%0A%0D%0A${content}"
				echo "$curtime 【微信推送】 新设备加入 " >> ${logfile}
				cat ${dir}mac_add | grep -v "^$"  >> ${logfile}
			fi
		fi	
			
		#设备上下线提醒
		if [ "$serverchan_notify_3" = "1" ] ; then
		    cat /proc/net/arp | grep -v "^$" | awk '{if($0~"br-lan") print}' | awk -F "[ ]+" '{print $4,$3,$1}' | sort -u > ${dir}arp_now
			#sed -i '$d' ${dir}arp_now
			cat ${dir}mac_all | awk -F' ' 'BEGIN{OFS=" "}{if($2==""){$2="0xF";}print;}' | awk -F' ' 'BEGIN{OFS=" "}{if($3==""){$3="0.0.0.0";}print;}' > ${dir}tmpfile
			awk -F' ' 'NR==FNR{a[$1]=$2" "$3;next}{for(i in a){if($1==i)$2=a[$1]}}1' ${dir}arp_now  ${dir}tmpfile >  ${dir}tmpfile2
			cat ${dir}tmpfile2 | awk '{ $4=null;print $0 }' >${dir}tmpfile
			#echo "$curtime check! "
			#sleep ${sleeptime}
			#awk -F "[ ]" 'NR==FNR{a[$1]=$2" "$3;next}{print $1" "a[$1]}'  ${dir}arp_now  ${dir}tmpfile >  ${dir}tmpfile2
			awk -F "[ ]" 'NR==FNR{a[$1]=$2;next}{print $2" "$1" "$3" "a[$1]}'  ${dir}mac_name  ${dir}tmpfile >  ${dir}tmpfile2
			awk -F' ' 'BEGIN{OFS=" "}{if($4==""){$4=$2;}print;}' ${dir}tmpfile2 > ${dir}mac_state_now_name
			touch ${dir}mac_state_last_name
			grep -F -v -f "${dir}mac_state_last_name" "${dir}mac_state_now_name" | sort | uniq > ${dir}mac_state_change_name
			if [ -s "${dir}mac_state_change_name" ] ; then
				cp ${dir}mac_state_now_name ${dir}mac_state_last_name
				echo "$curtime 【微信推送】 设备状态变化" >> ${logfile}
				cat ${dir}mac_state_change_name | sed 's/0x2/在线/g' | sed 's/0x0/离线/g' | sed 's/0xF/未知/g' >> ${logfile}
				echo "======↓历史设备状态↓======" >> ${logfile}
				cat ${dir}mac_state_now_name | sed 's/0x2/在线/g' | sed 's/0x0/离线/g' | sed 's/0xF/未知/g' >> ${logfile}
				cat /dev/null > /www/status/index.html
				cat /www/status/1 >> /www/status/index.html
				echo "<h4>Last Refresh Time  ${nowtime} </h4>" >> /www/status/index.html
				echo '<table border="1">' >> /www/status/index.html
				echo "<tr>" >> /www/status/index.html
				echo "<th>STATUS</th>" >> /www/status/index.html
				echo "<th>IP</th>" >> /www/status/index.html
				echo "<th>NAME</th>" >> /www/status/index.html
				echo "</tr>" >> /www/status/index.html
				cat /root/var/mac_state_now_name |awk '{ $2=null;print $0 }' | grep -v "^$" | awk -F "[ ]+" '{print $1"<td>"$2"</td><td>"$3"</td>"}' | sed 's:0x2:<td bgcolor="green">OnLine</td>:g' | sed 's:0x0:<td bgcolor="red">OffLine</td>:g' | sed 's:0xF:<td bgcolor="yellow">Lose</td>:g' | awk -F "[ ]+" '{print "<tr>"$0"</tr>"}' >> /www/status/index.html
				echo "</table>" >> /www/status/index.html
				sed -i 's/0x2/%e5%9c%a8%e7%ba%bf/g' ${dir}mac_state_change_name
				sed -i 's/0x0/%e7%a6%bb%e7%ba%bf/g' ${dir}mac_state_change_name
				sed -i 's/0xF/%e6%9c%aa%e7%9f%a5/g' ${dir}mac_state_change_name
				sed -i 's/0x2/%e5%9c%a8%e7%ba%bf/g' ${dir}mac_state_now_name
				sed -i 's/0x0/%e7%a6%bb%e7%ba%bf/g' ${dir}mac_state_now_name
				sed -i 's/0xF/%e6%9c%aa%e7%9f%a5/g' ${dir}mac_state_now_name
				title="%e3%80%90${hostname}%e3%80%91%e8%ae%be%e5%a4%87%e7%8a%b6%e6%80%81%e5%8f%98%e5%8c%96"
				content1=`cat ${dir}mac_state_change_name  |awk '{ $2=null;print $0 }' | grep -v "^$" | sed 's/$/ %0D%0A%0D%0A/'`
				content2=`cat ${dir}mac_state_now_name  |awk '{ $2=null;print $0 }' | grep -v "^$" | sed 's/$/ %0D%0A%0D%0A/'`
				#curl -s "http://sc.ftqq.com/$serverchan_sckey.send?text=${title}" -d "&desp=%e6%a3%80%e6%b5%8b%e6%97%b6%e9%97%b4%ef%bc%9a${nowtime}%0D%0A%0D%0A${content1}%0D%0A%0D%0A%3d%3d%3d%3d%3d%3d%e2%86%93%e5%8e%86%e5%8f%b2%e8%ae%be%e5%a4%87%e7%8a%b6%e6%80%81%e2%86%93%3d%3d%3d%3d%3d%3d%0D%0A%0D%0A${content2}"
			fi
		fi
	fi

else
	echo "$curtime 【路由断网】 当前网络不通！ " >> ${logfile}
fi

sleep ${sleeptime}
continue
done