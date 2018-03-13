# openwrt-device-status
在OPENWRT上通过脚本实现对连入设备的提醒、状态变化、外网地址变化的检测提醒

增加了夜间免打扰、获取路由名称并加到推送标题中等等


频繁的推送其实挺麻烦的，可以做个静态页面，把设备状态写进去
确保是外网可以访问路由器的前提下
访问  IP:端口/路径即可
例如 abc.top:8888/test
加到浏览器书签，直接访问即可查看当前所有设备在线状态替换如下代码到原来的地方

在/www/目录下建立status文件夹，内建一个文件1


设备上下线大约需要1~2分才能判断出来
先是arp表变化，然后脚本查到就会推送
当然不排除arp不更新的情况，这我也不知道什么原因

我是放在 /root/test.sh
然后建立/etc/init.d/serverchan
ln -s /etc/init.d/serverchan /etc/rc.d/S99serverchan


#!/bin/sh /etc/rc.common
# /etc/init.d/serverchan

START=99
STOP=20

start() {          
        echo start  
        sh /root/test.sh
}                   
   
stop() {            
        echo stop  
         pid=ps | grep "test.sh" | grep -v grep | awk '{print $1}'
         kill -9 $pid
}  
