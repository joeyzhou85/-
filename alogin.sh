#该shell脚本为主脚本文件，相关信息如下：
#功能：在多台主机上批量执行命令，提高工作效率。
#说明：通过expect完成登陆主机后的命令交互动作，详情见alogin.exp文件。
#     通过创建多个线程实现并发操作，默认并发15个线程。

#!/usr/bin/bash -
set -x           #详细输出日志

cat ip_list|grep -v ^$ > ip.tmp          #创建主机列表
rnum=`cat ip.tmp|grep -v ^$ |wc -l`      #主机数量统计
logdir=alogin_log                        #日志目录
total_log=$logdir/log_sum.log			 #总体日志
user="joey"							 #用户名
user_pass="+"					 #密码
root_pass="+"                     #管理员密码
command=`sed -e ':a;N;$!ba;s/\n/;/g' command_list`    #提取命令

if [ ! -d $logdir ]; then           #更新每次执行的日志目录，便于查验执行结果。
	mkdir $logdir
else
	rm $logdir/*
fi

function para_pro(){                #交互执行命令
  ./alogin.exp $1 $2 $3 $4 $5 $6
}

#
#以下代码用于创建多个线程，实现并发功能。
#

tmp_fifofile="/tmp/$$.fifo"
mkfifo $tmp_fifofile
exec 6<>$tmp_fifofile
rm $tmp_fifofile

thread=15                          #线程数量
for ((i=0;i<$thread;i++));do
  echo
done >& 6

for ((i=0;i<$rnum;i++));do
  read -u 6
  ip_addr=`sed -n $((i+1))\p ip.tmp|sed 's/\r//g'`
{
para_pro $user $ip_addr $user_pass $root_pass "$command" $logdir/$ip_addr.log >> $logdir/$ip_addr.log 2>&1 && {
	echo "$ip_addr is finished" >> $total_log
} ||{
	echo "$ip_addr is error" >> $total_log
}
	echo >& 6
}&
done
wait
rm ip.tmp
exec 6>&-
exit 0
