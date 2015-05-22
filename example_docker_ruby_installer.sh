#!/bin/bash
# assumes /sources contains the installation files
# assumes $2 is the file to install
# assumes $1 is the location to install it

cd /sources
tar xvzf $1.tar.gz
cd $1
./configure --prefix=$2 && make && make install
cd / && rm -r /sources/$1

echo "export PATH=\"\$PATH:$2/bin\"" >> /root/.bashrc

echo 'gem: --no-rdoc --no-ri' >> /.gemrc
echo 'gem: --no-rdoc --no-ri' >> ~/.gemrc
$2/bin/gem install bundler
