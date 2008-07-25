#	   user: iku
#	machine: openbsd.fi
#	   tree: /www/skel/data
#	   date: Fri Sep  7 21:01:42 2007

# ./bin
/set type=file uid=0 gid=0 mode=0700
bin             type=dir mode=0755
    spawn-php.sh
# ./bin
..


# ./fastcgi
fastcgi         type=dir mode=0755
# ./fastcgi
..


# ./logs
/set type=file uid=0 gid=0 mode=0640
logs            type=dir mode=0755
    access_log 
    error_log  
# ./logs
..


# ./modules
modules         type=dir mode=0755
# ./modules
..


# ./tmp
tmp             type=dir mode=0700
# ./tmp
..

..

