#!/bin/bash

# Script to see which keys are stored in a memcached server
# Warning: stats command is blocking, so be careful if you want to use this in production

SERVER=localhost
PORT=11211

stats=`echo -e "stats items \n quit" | nc $SERVER $PORT`

keys=`echo "$stats" | egrep "STAT.*number" | cut -d ':' -f 2 | xargs echo`

commands=""
for key in $keys ; do 
  commands="stats cachedump $key 100 \n $commands"
done

echo -e "$commands quit " | nc $SERVER $PORT | grep ITEM
