#!/bin/bash
 #**************************************************************************
 #
 # Software distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, 
 # either express or implied. This software is not affiliated with the 
 # Apache Software Foundation (ASF).
 #
 #**************************************************************************
 # Copyright (c)2001,2002,2003 Bryan Andrews. All rights reserved.
 # 
 # Bryan Andrews
 # bryan@apachetoolbox.com
 # http://www.apachetoolbox.com/
 # 
 #**************************************************************************

# thanks to David Drum <david@mu.org> for the suggestion!
unalias -a

if [ "$1" = "--clean" ] || [ "$1" = "-c" ]; then
	echo Deleting installwatch...
	rm -R -f bin/atb/installwatch.s*
	if [ -d apache_1.3.* ]; then
	 echo Deleting apache...
 	 rm -R -f apache_1.3.*
 	fi
 	for i in src/*; do
  		if [ -d $i ];then
  		 echo Deleting directory $i...
  		 rm -rf $i
  		fi
 	done
 	test -d logs && rm -R -f logs
	# Kevin was complaining :)
	# test -f etc/config.cache && rm -R -f etc/config.cache
	echo "Source files cleaned."
 	exit 0
fi


#	basic help menu

if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
echo -e "
Usage: $0 [OPTION]...
Configure Apache with a large variety of options and modules.

  -h,  --help\tthis help menu
  -f,  --fast\tuse an existing config.cache file and install 
\t\twithout any prompts
  -u,  --update\tautomatically update this program from the 
\t\tapachetoolbox.com website
  -c,  --clean\tclean out all the src directory but retain
\t\tall the source files
  -nc, --nocolor\tdisable color support

Report bugs to <support@apachetoolbox.com>
Online support forum at http://www.apachetoolbox.com
"
exit 0
fi



#######################################################################
#       if --update or -u where used, use lynx to run
#       a shell script stored on my website to check for
#       updates to ATB and download the latest version if
#       needed
#######################################################################
if [ "$1" = "--update" ] || [ "$1" = "-u" ]; then

	echo -e  "Self-updating Apache Toolbox.\n"
	if [ `id -ur` -eq 0 ]; then
		echo -e  "ERROR : Update is not allowed to run as root.\n"
		echo -e "        Please run the update as an unprivilegied user. If the\n"
		echo -e "        ATB files are owned by root you will have to chown them\n"
		echo -e "        to your user.\n"
		exit 1
	else
		#thanks to go-gnome.com for the kick ass idea. -Bryan
		lynx -source http://www.apachetoolbox.com/updates | /bin/sh
		exit 0
	fi
	exit 0
fi





# Set color usage
if [ "$1" = "-nc" ] || [ "$1" = "--nocolor" ] || [ "$2" = "-nc" ] || [ "$2" = "--nocolor" ]; then
	ATB_COLOR=0
else
	ATB_COLOR=1
fi

#	load all versions and default settings and functions
. etc/defaults.conf
. etc/functions.conf
. etc/external.conf


#	if a cached settings file exists load options from 
#	that

if [ -f $root/etc/config.cache ]; then
	. bin/atb/load-settings
	echo "[$MENUTRUE] Loaded saved settings!"
fi


#######################################################################
# Verify root authority
#######################################################################
# Root isn't required as long as you install everything in a directory
# where you have rights to.

if [ "$1" != "--fast" ] && [ "$1" != "-f" ]; then
    root_string=`id | grep root`

    if [ -z "$root_string" ]
    then
        ROOT_USER=$FALSE
        echo_line
        echo -e "This script must be run by root if you plan on \ninstalling anything in their default locations.  You must \ninstall everything in a directory that you have rights to \nif you are not root!"
        echo_line
        IsYNLoop "Do you wish to continue anyway?"
        case "$?" in    
            $NO)        
                exit
                ;;
        esac
    else
        ROOT_USER=$TRUE
    fi
fi
#######################################################################
# Main Menu
#######################################################################

if [ "$1" = "--fast" ] || [ "$1" = "-f" ]; then
 	JUSTDL=$TRUE
 	CONTINUE=$TRUE
 	FAST=$TRUE
else
 	CONTINUE=$FALSE
fi

#	main menu


    CHOICE=
    while [ $CONTINUE -eq $FALSE ]
    do
        clear 


	banner
comp_menu_item apache "$TRUE" " Apache submenu...\n"
comp_menu_item php "$INSTALL_PHP" "    PHP submenu (v$PHP)...\n"
comp_menu_item rpm "$MAKERPM" "    Build an RPM with your choices?\n"
comp_menu_item page2 "$INSTALL_CONTRIB_checkbox" "  Apache Modules PAGE 2 ...\n"
echo_line
comp_menu_item 1 "$INSTALL_GD" "GD $GD" TAB;TAB;TAB; comp_menu_item 2 "$FALSE" "-SQL DB Menus-\n"
comp_menu_item 3 "$INSTALL_MODPYTHON" "Mod Python $MODPYTHON" TAB;TAB;TAB; comp_menu_item 4 "$INSTALL_SSL" "Mod_SSL+OpenSSL\n"
comp_menu_item 5 "$INSTALL_MODTHROTTLE" "-Mod Throttle $THROTTLE"; TAB; comp_menu_item 6 "$INSTALL_WEBDAV" "-WebDAV $WEBDAV$n";
comp_menu_item 7 "$INSTALL_MODFASTCGI" "-Mod FastCGI"; TAB;TAB; comp_menu_item 8 "$INSTALL_MODAUTHNDS" "-Mod AuthNDS $MODAUTHNDS$n";
comp_menu_item 9 "$INSTALL_MODFRONTPAGE" "-Frontpage 2002"; TAB;TAB; comp_menu_item 10 "$INSTALL_MODGZIP" "-Mod GZIP $MODGZIP$n";
comp_menu_item 11 "$INSTALL_MODDYNVHOST" "-Mod DynaVHost"; TAB;TAB; comp_menu_item 12 "$INSTALL_MODROAMING" "-Mod Roaming$n";
comp_menu_item 13 "$INSTALL_MODACCESSREF" "-Mod AccessRef $MODACCESSREF"; TAB; comp_menu_item 14 "$INSTALL_MODAUTHSYS" "-Mod AuthSYS$n"
comp_menu_item 15 "$INSTALL_MODBANDWIDTH" "-Mod Bandwidth"; TAB;TAB; comp_menu_item 16 "$INSTALL_MODPERL" "-Mod Perl $MODPERL$n"
comp_menu_item 17 "$INSTALL_MODAUTHLDAP" "-Mod Auth LDAP"; TAB;TAB; comp_menu_item 18 "$INSTALL_MODJK" "-Mod JK$n"
comp_menu_item 19 "$INSTALL_MODAUTHRADIUS" "-Mod Auth Radius"; TAB; comp_menu_item 20 "$INSTALL_MODAUTHPOP3" "-Mod Auth POP3$n";
comp_menu_item 21 "$INSTALL_MODLAYOUT" "-Mod Layout $MODLAYOUT"; TAB;TAB; comp_menu_item 22 "$INSTALL_MODTCL" "-Mod DTCL$n";

        say "$t q) Quit$t$t 99) Descriptions$n$t$t go) Compile selections...$n"

        echo_line
        say "Choice [?] "
        read CHOICE
        case "$CHOICE" in
	    [aA][pP][aA][cC][hH][eE])
		. etc/apache.menu
		;;
            [pP][hH][pP])
		. etc/php.menu
                ;;
	    [rR][pP][mM])
                test_choice MAKERPM $MAKERPM
                MAKERPM=$var		
		echo -e "If this doesn't work for you checkout the $root/contrib/ directory for another option!"
		HitAnyKey
		;;
	    [pP][aA][gG][eE]2)
		. etc/page2.menu
		;;
            1)
        	test_choice INSTALL_GD $INSTALL_GD
		INSTALL_GD=$var
                ;;
            2)
		. etc/sql.menu 
		;;
            3)
		test_choice INSTALL_MODPYTHON $INSTALL_MODPYTHON
                INSTALL_MODPYTHON=$var
		;;
            4)  
                test_choice INSTALL_SSL $INSTALL_SSL
                INSTALL_SSL=$var
                ;;
            5)
                test_choice INSTALL_MODTHROTTLE $INSTALL_MODTHROTTLE
                INSTALL_MODTHROTTLE=$var
                if [ $var -eq $TRUE ] ;then INSTALL_MODBANDWIDTH=$FALSE;fi
                ;;
            6)
                test_choice INSTALL_WEBDAV $INSTALL_WEBDAV
                INSTALL_WEBDAV=$var
                ;;
            7)
                test_choice INSTALL_MODFASTCGI $INSTALL_MODFASTCGI
                INSTALL_MODFASTCGI=$var
                ;;
            8)
		IsYNLoop "IPX must be supported on the host before this will compile!$n  Do you wish to continue anyway?"
	        case "$?" in
        	    $NO)
                	;;
		    *)
        	        test_choice INSTALL_MODAUTHNDS $INSTALL_MODAUTHNDS
	                INSTALL_MODAUTHNDS=$var
			;;	
        	esac
                ;;
            9)
		if [ $ROOT_USER = $FALSE ];then
			echo -e "Root is required to install Frontpage 2002 Extensions!"
			HitAnyKey
		else
	                test_choice INSTALL_MODFRONTPAGE $INSTALL_MODFRONTPAGE
	                INSTALL_MODFRONTPAGE=$var
		fi
                ;;
            10)
                test_choice INSTALL_MODGZIP $INSTALL_MODGZIP
                INSTALL_MODGZIP=$var
                ;;
            11)
                test_choice INSTALL_MODDYNVHOST $INSTALL_MODDYNVHOST
                INSTALL_MODDYNVHOST=$var
                ;;
            12)
                test_choice INSTALL_MODROAMING $INSTALL_MODROAMING
                INSTALL_MODROAMING=$var
                ;;
            13)
                test_choice INSTALL_MODACCESSREF $INSTALL_MODACCESSREF
                INSTALL_MODACCESSREF=$var
                ;;
            14)
                test_choice INSTALL_MODAUTHSYS $INSTALL_MODAUTHSYS
                INSTALL_MODAUTHSYS=$var
		say "This mod_auth_sys.c has been modified from its original code by$nBistop <bishop@platypus.bc.ca>. Original code by Howard Fear.$n"
		HitAnyKey
                ;;
            15)
                test_choice INSTALL_MODBANDWIDTH $INSTALL_MODBANDWIDTH
                INSTALL_MODBANDWIDTH=$var
                if [ $var -eq $TRUE ] ;then INSTALL_MODTHROTTLE=$FALSE;fi
                ;;
            16)
		if [ $ROOT_USER = $FALSE ];then
			echo -e "Root is required to install mod_perl!"
			HitAnyKey
		else
			LWPversion=`perl -e 'require LWP::UserAgent; print "$LWP::UserAgent::VERSION";' 2>/dev/null`
			HTMLversion=`perl -e 'require HTML::HeadParser; print "$HTML::HeadParser::VERSION";' 2>/dev/null`
			CGIversion=`perl -e 'require CGI; print "$CGI::VERSION";' 2>/dev/null`
			# for debugging
			#echo "lwp=$LWPversion - html=$HTMLversion - cgi=$CGIversion"
			if [ -z $LWPversion ] || [ -z $HTMLversion ] || [ -z $CGIversion ];then
			 if [ -z $LWPversion ]; then echo "LWP::UserAgent not installed!"; fi
			 if [ -z $HTMLversion ]; then echo "HTML::HeadParser not installed!"; fi
			 if [ -z $CGIversion ]; then echo "CGI.pm v2.39+ is not installed!"; fi
			 echo -e "Type \"perl -MCPAN -e shell\" to start the perl CPAN\nshell, then \"install LWP::UserAgent\" to install the LWP::UserAgent module! Substitute LWP::UserAgent for any perl module.\n"
			 HitAnyKey
			 INSTALL_MODPERL=$FALSE
			else
			 test_choice INSTALL_MODPERL $INSTALL_MODPERL
			 INSTALL_MODPERL=$var
			fi
		fi
		;;
            17)
                test_choice INSTALL_MODAUTHLDAP $INSTALL_MODAUTHLDAP
                INSTALL_MODAUTHLDAP=$var
                ;;
	    18)
	        test_choice INSTALL_MODJK $INSTALL_MODJK
		INSTALL_MODJK=$var
		;;
            19)
                test_choice INSTALL_MODAUTHRADIUS $INSTALL_MODAUTHRADIUS
                INSTALL_MODAUTHRADIUS=$var
                ;;
            20)
                test_choice INSTALL_MODAUTHPOP3 $INSTALL_MODAUTHPOP3
                INSTALL_MODAUTHPOP3=$var
		echo "This module has been known to cause problems with other modules, like PHP. If you have problems compiling anything with mod_auth_pop3, disable mod_auth_pop3 and see if it works."
		HitAnyKey
                ;;
            21)
                test_choice INSTALL_MODLAYOUT $INSTALL_MODLAYOUT
                INSTALL_MODLAYOUT=$var
                ;;
            22)
		. bin/contrib/mod_dtcl-detection
                ;;
            go)
                CONTINUE=$TRUE
		. $root/bin/atb/save-settings
                ;;
            q)
		echo -e "So long, and thanks for all the fish!\n"
                exit
                ;;
            99)
		print_descriptions;
		HitAnyKey
                ;;
            *)   
                echo "Invalid Selection..."
		HitAnyKey
        esac
    done





#	make sure the log directory exists


notice "$MENUTRUE" "Testing for Log directory..."
if [ ! -d $logdir ];then
 mkdir $logdir
 if [ ! -d $logdir ] ;then echo " [$FAILED]"; exit 1; else echo " [$DONE]"; fi
else
 echo " [$DONE]"
fi


#	make sure the src directory exists


notice "$MENUTRUE" "Testing for src directory..."
if [ ! -d $root/src ];then
 mkdir $root/src
 if [ ! -d $root/src ] ;then echo " [$FALSE]"; exit 1; else echo " [$DONE]"; fi
else
 echo " [$DONE]"
fi



#######################################################################
# RPM Testing
#######################################################################


#	if the rpm binary is found test for rpms not wanted


if [ -x /bin/rpm ] || [ -x /usr/bin/rpm ] || [ -x /usr/local/bin/rpm ] || [ -x $LOCAL_PATH/bin/rpm ]
then

 echo  ---------------------------------------------------------------------
 echo  --------------------- Scanning for RPM\'s ----------------------------
 echo  ---------------------------------------------------------------------


 rpm -qa > $root/etc/rpm.tmp

 rpmtest "php-[0-9].[0-9]" "PHP";
 rpmtest "php-imap" "PHP IMAP"
 rpmtest "php-ldap" "PHP LDAP"
 rpmtest "php-pgsql" "PHP PGSQL"
 rpmtest "apache-[0-9].[0-9]" "Apache"
 rpmtest "apache-devel-[0-9].[0-9]-[0-9]" "Apache Devel"
 rpmtest "mod_perl" "Mod_Perl"
 rpmtest "mod_perl-devel" "Mod_Perl Devel"
 notice $MENUTRUE " ** If your going to use an RPM package (like openssl) you better have the DEVEL rpm installed as well! **\n"

 if [ -f $root/etc/rpm.tmp ]; then rm -rf $root/etc/rpm.tmp; fi

if [ -z $FAST ]; then
 if [ "$rpm" = "1" ]
 then
  echo_line
  IsYNLoop "RPMs that will probably cause problems where found!\nDo you wish to continue anyway? (be careful)"
   case "$?" in
	$NO)
		exit
		;;
	*)
		;;
   esac
 fi
# end $FAST check
fi

else
 echo "[$MENUTRUE] -RPM system not found, skipping check."
 MAKERPM=$FALSE
fi


#	check for wget and install it if it isnt found
. $root/bin/atb/wget

#	check for an existing installwatch binary
#	in the bin directory, if it isn't found
#	compile and copy it
. $root/bin/atb/installwatch


notice "$MENUTRUE" "Setting up Apache source...\n"

if [ -d apache_$APACHE ]; then
 test -f $root/apache_$APACHE/go.sh && $MV -f $root/apache_$APACHE/go.sh $root/apache_$APACHE/go.sh-`date +%m-%d-%y_%H.%M`

 if [ -f $root/apache_$APACHE/conf/httpd.conf-dist~ ]; then
  $CP -f $root/apache_$APACHE/conf/httpd.conf-dist~ $root/apache_$APACHE/conf/httpd.conf-dist
  notice "$MENUTRUE" " Apache httpd.conf file restored.\n"
 else
  $CP -f $root/apache_$APACHE/conf/httpd.conf-dist $root/apache_$APACHE/conf/httpd.conf-dist~
  notice "$MENUTRUE" " Apache httpd.conf file backed up.\n"
 fi

#needed to hack the version of HTTPD and other info...
 if [ -f $root/apache_$APACHE/src/include/httpd.h~ ]; then
  $CP -f $root/apache_$APACHE/src/include/httpd.h~ $root/apache_$APACHE/src/include/httpd.h
  notice "$MENUTRUE" " Apache httpd.h file restored.\n"
 else
  $CP -f $root/apache_$APACHE/src/include/httpd.h $root/apache_$APACHE/src/include/httpd.h~
  notice "$MENUTRUE" " Apache httpd.h file backed up.\n"
 fi

 if [ -z $FAST ]; then
  IsYNLoop "Apache source already found, backup before continuing?"
  case "$?" in
	$NO)
		;;
	*)
		cp -Rf $root/apache_$APACHE $root/apache_"$APACHE"_`date +%m-%d-%y_%H.%M`
		notice "$MENUTRUE" " Old apache source backed up to $root/apache_"$APACHE"_`date +%m-%d-%y_%H.%M`\n"
		;;
  esac
 fi

else 
 cd $root/src
 check_source "apache_$APACHE.tar.gz" "http://ftp.epix.net/apache/httpd/apache_$APACHE.tar.gz"
 explode apache_$APACHE.tar.gz
 $MV -f $root/src/apache_$APACHE $root/apache_$APACHE >/dev/null
 $CP -f $root/apache_$APACHE/conf/httpd.conf-dist $root/apache_$APACHE/conf/httpd.conf-dist~
 notice "$MENUTRUE" " Uncompressed Apache source...\n"
 cd $root
fi



#mkdir -p $APACHE_PATH/../lib $APACHE_PATH/../bin $APACHE_PATH/../man/man{1,2,3,4,5,6,7,8,9,l} $APACHE_PATH/../include $PHP_PATH


#	at this point the apache source should exist in the ATB root,
#	otherwise we've had a huge problem and should exit

if [ ! -d apache_$APACHE ]; then notice "$MENUFALSE" "Uncompressing Apache source failed!"; exit; fi



#	preconfigure apache, this is needed by SSL and a few others

notice "$MENUTRUE" " Getting apache pre-configured..."
cd apache_$APACHE
./configure > $logdir/apache-preconfigure.log
echo " [$DONE]"


#	Add support for SSI's via .shtml to the httpd.conf file

notice "$MENUTRUE" " Updating Apache httpd.conf-dist for CGI/SSI support..."
echo -e "\nAddHandler cgi-script .cgi\nAddType text/html .shtml\nAddHandler server-parsed .shtml\n" >> $root/apache_$APACHE/conf/httpd.conf-dist
echo " [$DONE]"

cd $root



#	at this point apache is all set and ready to have modules add
#	to it.  we add modules from here on.



#---------------------------------- Default Apache Mods ---------------------------------------

. $root/bin/apache/apache_mods

#----------------------------------- Apache IPv6 Support --------------------------------------

test $INSTALL_APACHE_IPV6 -eq $TRUE && . $root/bin/apache/apache_ipv6

#------------------------------------- GD ---------------------------------------------------

test $INSTALL_GD -eq $TRUE && . $root/bin/gd/gd

#------------------------------------ Apache mods page 2---------------------------------------

test $INSTALL_CONTRIB_checkbox -eq $TRUE && . $root/bin/contrib/contrib

#------------------------------------- SSL ---------------------------------------------------

test $INSTALL_SSL -eq $TRUE && . $root/bin/ssl/ssl

#----------------------------------- Mod Backhand --------------------------------------

test $INSTALL_MODBACKHAND -eq $TRUE && . $root/bin/contrib/mod_backhand

#----------------------------------- Mod DNS --------------------------------------

test $INSTALL_MODDNS -eq $TRUE && . $root/bin/contrib/mod_dns

#----------------------------------- Mod watch --------------------------------------

test $INSTALL_MODWATCH -eq $TRUE && . $root/bin/contrib/mod_watch

#----------------------------------- Mod Trigger --------------------------------------

test $INSTALL_MODTRIGGER -eq $TRUE && . $root/bin/contrib/mod_trigger

#----------------------------------- Mod Filter --------------------------------------

test $INSTALL_MODFILTER -eq $TRUE && . $root/bin/contrib/mod_filter

#----------------------------------- Mod Auth Samba --------------------------------------

test $INSTALL_MODAUTHSAMBA -eq $TRUE && . $root/bin/contrib/mod_auth_samba

#----------------------------------- Mod Index RSS --------------------------------------

test $INSTALL_MODINDEXRSS -eq $TRUE && . $root/bin/contrib/mod_index_rss

#----------------------------------- Mod Random --------------------------------------

test $INSTALL_MODRANDOM -eq $TRUE && . $root/bin/contrib/mod_random

#----------------------------------- Mod MP3 --------------------------------------

test $INSTALL_MODMP3 -eq $TRUE && . $root/bin/contri/mod_mp3

#------------------------------------- MOD AuthNDS  ---------------------------------------------------


if [ $INSTALL_MODAUTHNDS -eq $TRUE ]
then

 
#	test for IPX support before we add mod_auth_nds
 
 notice "$MENUTRUE" "+Testing for IPX support needed by Mod_AuthNDS..."
 test=`/sbin/ifconfig|grep IPX`
 if [ "$test" ] 
 then
  echo " [$DONE]"
  . $root/bin/contrib/mod_auth_nds
 else
  echo_line
  echo " [$TXT_FAILED]"
  echo_line
  notice "$MENUFALSE" "  +IPX support not found... Mod_AuthNDS will not be installed\n"
  echo_line
  if [ -z $FAST ];then
   HitAnyKey
  fi
 fi

fi

#------------------------------------- MOD AccessRef ---------------------------------------------------

test $INSTALL_MODACCESSREF -eq $TRUE && . $root/bin/contrib/mod_access_ref

#------------------------------------- MOD Python ---------------------------------------------------

test $INSTALL_MODPYTHON -eq $TRUE && . $root/bin/contrib/mod_python

#------------------------------------- MOD_Layout --------------------------------------------

test $INSTALL_MODLAYOUT -eq $TRUE && . $root/bin/contrib/mod_layout

#------------------------------------- MOD_Auth_LDAP ---------------------------------------------------

test $INSTALL_MODAUTHLDAP -eq $TRUE && . $root/bin/contrib/mod_auth_ldap

#------------------------------------- MOD Perl ------------------------------------------------

test $INSTALL_MODPERL -eq $TRUE && . $root/bin/contrib/mod_perl

#------------------------------------- MOD Bandwidth -----------------------------------------------

test $INSTALL_MODBANDWIDTH -eq $TRUE && . $root/bin/contrib/mod_bandwidth

#------------------------------------- MOD PCGI2 -----------------------------------------------

test $INSTALL_MODPCGI2 -eq $TRUE && . $root/bin/contrib/mod_pcgi2

#------------------------------------- MOD Frontpage -----------------------------------------------

test $INSTALL_MODFRONTPAGE -eq $TRUE && . $root/bin/contrib/mod_frontpage

#------------------------------------- MOD AuthSYS ---------------------------------------------------

test $INSTALL_MODAUTHSYS -eq $TRUE && . $root/bin/contrib/mod_auth_sys

#------------------------------------- MOD Roaming  ---------------------------------------------------

test $INSTALL_MODROAMING -eq $TRUE && . $root/bin/contrib/mod_roaming

#------------------------------------- WebDAV ---------------------------------------------------

test $INSTALL_WEBDAV -eq $TRUE && . $root/bin/contrib/mod_webdav

#------------------------------------- MOD Throttle ---------------------------------------------------

test $INSTALL_MODTHROTTLE -eq $TRUE && . $root/bin/contrib/mod_throttle

#------------------------------------- Mod FASTCGI ---------------------------------------------------

test $INSTALL_MODFASTCGI -eq $TRUE && . $root/bin/contrib/mod_fastcgi

#------------------------------------- Mod Tcl -----------------------------------------

test $INSTALL_MODTCL -eq $TRUE && . $root/bin/contrib/mod_tcl

#------------------------------------- Mod AuthPOP3 ------------------------------------------------

test $INSTALL_MODAUTHPOP3 -eq $TRUE && . $root/bin/contrib/mod_auth_pop3

#------------------------------------- Mod AuthRadius ------------------------------------------------

test $INSTALL_MODAUTHRADIUS -eq $TRUE && . $root/bin/contrib/mod_auth_radius

#------------------------------------- MOD DynaVhost ---------------------------------------------------

test $INSTALL_MODDYNVHOST -eq $TRUE && . $root/bin/contrib/mod_dynavhost

#------------------------------------- MOD Gzip ---------------------------------------------------

test $INSTALL_MODGZIP -eq $TRUE && . $root/bin/contrib/mod_gzip

#----------------------------------- Mod_Auth_PAM ---------------------------------
  
test $INSTALL_MODAUTHPAM -eq $TRUE && . $root/bin/contrib/mod_auth_pam
    
#----------------------------------- Mod_Auth_Kerb --------------------------------

test $INSTALL_MODAUTHKERB -eq $TRUE && . $root/bin/contrib/mod_auth_kerb

#----------------------------------- Mod_DoS_Evasive -------------------------------

test $INSTALL_MODDOSEVASIVE -eq $TRUE && . $root/bin/contrib/mod_dos_evasive

#------------------------------------- MYSQL ---------------------------------------------------

test $INSTALL_MYSQL -eq $TRUE && . $root/bin/sql/mysql

#------------------------------------- PgSQL ---------------------------------------------------

test $INSTALL_PGSQL -eq $TRUE && . $root/bin/sql/pgsql

#------------------------------------- Mod_Auth_MySQL -------------------------------------------

test $INSTALL_MODAUTHMYSQL -eq $TRUE && . $root/bin/contrib/mod_auth_mysql

#------------------------------------- PHP ---------------------------------------------------

test $INSTALL_PHP -eq $TRUE && . $root/bin/php/php

#------------------------------------- Hacking Apache -------------------------------------------

test $APACHE_HACK -eq $TRUE && . $root/bin/apache/apache_hacking

#------------------------------------- Mod_JK -------- -------------------------------------------

test $INSTALL_MODJK -eq $TRUE && . $root/bin/contrib/mod_jk

#	End of apache module section, start the apache configuration section




notice "$MENUTRUE" "Setting up Apache for compilation...\n"
cd $root/apache_$APACHE

#	if an existing configuration script exists then delete it

if [ -f go.sh ];then rm -rf go.sh; fi

if [ $INSTALL_SSL -eq $TRUE ];then
 notice "$MENUTRUE" " Adding SSL info..."
  echo -e "$MOD_SSL_CONFIG" >> go.sh
 echo " [$DONE]"
fi

notice "$MENUTRUE" " Adding extra CFLAGS..."
 echo -e "export CFLAGS=\"$APACHECFLAGS\"" >> go.sh
echo " [$DONE]"

notice "$MENUTRUE" " Adding extra LIBS..."
 echo -e "export LIBS=\"$APACHELIBS\"" >> go.sh
echo " [$DONE]"

notice "$MENUTRUE" " Adding extra INCLUDES..."
 echo -e "export INCLUDES=\"$APACHEINCLUDES\"" >> go.sh
echo " [$DONE]"


notice "$MENUTRUE" " Creating Apache's configuration script..."
 if [ "x$APACHELAYOUT" != "x$FALSE" ]; then
  echo -e " -Layout used- \c"
  echo -e "./configure --with-layout=\"$APACHELAYOUT\" $r$APACHECFG" >> go.sh
 else
  echo -e " -Prefix used- \c"
  echo -e "./configure --prefix=$APACHE_PATH $r$APACHECFG" >> go.sh
 fi
 chmod a+x go.sh
echo " [$DONE]"


#	unless --fast was used ask the user if he/she wants
#	to manually edit the configuration script before it's ran.

if [ -z $FAST ]; then
echo_line
IsYNLoop "Do you wish to edit the apache configuration script?"
        case "$?" in   
            $NO)
                ;;
            $YES)
#--------------------------------------------------------------------------------------
while [ -z "$EEDITOR" ]
do
	echo
	echo
	say "Enter the name if the text editor you would like to\nuse to edit the apache configureation script [pico]: "
	read EEDITOR
	if [ -z "$EEDITOR" ]; then
		echo "No editor specified, defaulting to pico."
		EEDITOR=pico
	fi
done
echo "Your about to edit the configuration script for apache..."
HitAnyKey
$EEDITOR go.sh
#--------------------------------------------------------------------------------------
                ;;
        esac
fi




#	Start of the beta RPM creation system

if [ $MAKERPM -eq $TRUE ]
then

 notice "$MENUTRUE" "RPM build started... [BETA]\n"
 notice "$MENUTRUE" " Configuring Apache source...\n"
 ./go.sh &> $logdir/apache-configure.log
 notice "$MENUTRUE" "Done Configuring Apache source\n\n\n"
echo_line
say "Apache about to be installed, this will overwrite your current version, make sure \
you have a complete backup before you continue! Hit CTRL-C to abort now.\n"
HitAnyKey

inst apache

if [ -f $rpm/rpmfiles.txt ]; then rm -rf $rpm/rpmfiles.txt; fi
if [ -f $root/rpm/$PACKAGE.spec ]; then rm -rf $root/rpm/$PACKAGE.spec; fi
if ! [ -d $root/rpm ]; then mkdir $root/rpm; fi

for i in `ls -1 $logdir/*.iw`; do 
 cat $i >> $root/rpm/rpmfiles.txt
done
notice "$MENUTRUE" " Compiled list of all installwatch logs...\n"

# weed out src files
grep -v $root $root/rpm/rpmfiles.txt > $root/rpm/rpmfiles.new
if [ -f $root/rpm/rpmfiles.new ]; then $MV -f $root/rpm/rpmfiles.new $root/rpm/rpmfiles.txt; fi


notice "$MENUTRUE" " Removed files copied to source from file list...\n"

cat > $root/rpm/$PACKAGE.spec << EOF
Summary:   $PACKAGE was used to build this custom RPM
Name:      $PACKAGE
Version:   $VER
Release:   $RPMVER
Copyright: GPL
Packager:  $PACKAGE
Group:     System Environment/Daemons
Source:    $PACKAGE-$VER.tar.gz
BuildRoot: /tmp/buildroot

%description
Built with $PACKAGE.

%prep
%setup
%build
%install
%post   
%postun 
%clean  
%files 
EOF
      
notice "$MENUTRUE" " Created headers in the .spec file...\n"
awk '$2=="open"||$2=="link" {print $3} ; $2=="rename" {print $4}' < $root/rpm/rpmfiles.txt | grep ^/ | \
egrep -v 'perllocal.pod|/dev/null|$HOME' | sort | uniq > $root/rpm/rpmfiles.new
if [ -f $root/rpm/rpmfiles.new ]; then mv -f $root/rpm/rpmfiles.new $root/rpm/rpmfiles.txt; fi
notice "$MENUTRUE" " Rebuilt the file list...\n"   

#weed out directories
for each in `cat $root/rpm/rpmfiles.txt`
do
   if [ -f $each ]
   then
      echo $each >> $root/rpm/$PACKAGE.spec
   fi
done 
notice "$MENUTRUE" " Copied file list to the .spec template...\n"

if ! [ -d /usr/src/redhat ]; then mkdir /usr/src/redhat; fi
if ! [ -d /usr/src/redhat/SOURCES ]; then mkdir /usr/src/redhat/SOURCES; fi
if [ -f /usr/src/redhat/SOURCES/$PACKAGE-$VER.tar.gz ]; then rm -rf /usr/src/redhat/SOURCES/$PACKAGE-$VER.tar.gz; fi

notice "$MENUTRUE" " Creating empty tar for the build...\n"
if [ -d /usr/src/redhat/SOURCES/$PACKAGE-$VER ]; then rm -rf /usr/src/redhat/SOURCES/$PACKAGE-$VER*; fi
mkdir /usr/src/redhat/SOURCES/$PACKAGE-$VER
cd /usr/src/redhat/SOURCES/
tar -czvf $PACKAGE-$VER.tar.gz $PACKAGE-$VER

cd /tmp
notice "$MENUTRUE" " Creating fake symbolic link for the RPM build...\n"
ln -sf / /tmp/buildroot

notice "$MENUTRUE" " Building the RPM...\n"
rpm -bb $root/rpm/$PACKAGE.spec > $logdir/rpmbuild.log

notice "$MENUTRUE" " Cleaning up temp files...\n"
/bin/rm -rf /usr/src/redhat/SOURCES/$PACKAGE-$VERSION
/bin/rm -rf /usr/src/redhat/SOURCES/$PACKAGE-$VERSION.tar.gz
rm -rf /tmp/buildroot

if [ -f /usr/src/redhat/RPMS/*/Apachetoolbox-*.rpm ]; then
 mv -f /usr/src/redhat/RPMS/*/Apachetoolbox-*.rpm $root/rpm
 notice "$MENUTRUE" " RPM moved to $root/rpm\n"
 notice "$MENUTRUE" "RPM built successfully!\n"
 rm -rf $root/rpm/rpmfiles.txt
else
 notice "$MENUFALSE" " RPM Wasn't created!\n"
fi




#	end of the beta RPM creation system


else


#	if the RPM system wasn't selected run configure and watch for errors


 echo
 notice "$MENUTRUE" " Configuring Apache source...\n"
 echo
 ./go.sh
 if [ $? -ne 0 ];then echo -e "\n****ERRORS WHERE DETECTED!****"; fi
 notice "$MENUTRUE" "Done Configuring Apache source\n\n\n"
 echo_line
 echo "If there where _no_ errors run \"cd apache_$APACHE;make\" now."
 if [ $INSTALL_SSL -eq $TRUE ]; then echo "Follow the instructions to make the SSL certificate before you install apache."; fi
 echo -e "Run \"make install\" in the apache source directory to install\napache $APACHE after you've successfully compiled it."
 echo -e "Please visit www.apachetoolbox.com for updates and the support forum."
 echo_line

fi
