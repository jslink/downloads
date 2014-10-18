#! /bin/sh
# Free Shadowsocks Server
# Powered By JSLINK.ORG
#        Freedom @ 2014
export PATH='/bin:/sbin:/usr/bin:/usr/sbin:/tmp/data/bin:/tmp/data/sbin:/tmp/data/usr/bin:/tmp/data/usr/sbin:/tmp/data/usr'
export LD_LIBRARY_PATH='/lib:/usr/lib:/tmp/data/lib:/tmp/data/usr/lib:/tmp/data/usr:/tmp/data/usr/lib:/tmp/data/usr/lib/python2.7:/tmp/data/usr/lib/python2.7/site-packages:/tmp/data/usr/lib/python2.7/lib-dynload'


conf=/etc/config/shadowsocks.json
key=(需要key的到http://www.jslink.org留言)

curl -sI --socks5 127.0.0.1:65500 -o /dev/null http://www.microsoft.com
[ $? -eq 0 ] || {
	key="`echo -n $key\`date +%Y-%m-%d\`|md5sum|awk '{print $1}'`"
	curl  -A 'Freedom' -m 10 -sd "k=$key&t=`date +%Y%m%d%H%M%S`" 'http://www.jslink.org/shadowsocks.php' >/tmp/shadowsocks.json.tmp
	[ -s /tmp/shadowsocks.json.tmp ] && {
		cp -rf /tmp/shadowsocks.json.tmp $conf
		rm -rf /tmp/shadowsocks.json.tmp
		/etc/init.d/shadowsocks restart
	}
}
