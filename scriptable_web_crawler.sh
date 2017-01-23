export NC_CMD=`which nc`
#echo -n "GET / HTTP/1.0\r\n\r\n" | nc $IP $PORT
read -p "Path [/]: " PATH
case $PATH in
  [/]* ) echo "";;
  * ) export PATH="/";;
esac

read -p "HOSTNAME/IP [www.google.com]: " IP
if [ "${IP}" = "" ]; then
  export IP="www.google.com"
fi

case $PATH in
  [/]* ) echo "";;
  * ) export PATH="/";;
esac


read -p "PORT [80]: " PORT
case $PORT in
  [0123456789]* ) echo "";;
  * ) export PORT=80;;
esac
printf "GET ${PATH} HTTP/1.0\r\n\r\n" | ${NC_CMD} ${IP} ${PORT}
