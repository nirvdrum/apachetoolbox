#!/bin/sh
# create rpm with ApacheToolbox

# Copyright (c)2001 Stuart Donaldson, All rights reserved.
# Stuart Donaldson
# stu@asyn.com
#
# This software is distributed AS-IS, WITHOUT WARRANTY OF ANY KIND, either
# express or implied.  
#
# Permission is granted to use this script for any legal purpose, 
# provide the above copyright notice is maintained.
#
. etc/versions.conf
. etc/defaults.conf
. etc/functions.conf

usage() {
cat <<EOF
  $0 [package] [symlinks...]
  
   Run install.sh to build and test your installation first.
   Then run $0 from the same directory install.sh is in.  It
   will take the etc/config.cache file and and the source files
   located under ./src and create source and binary rpms.

   package = location of $PACKAGE-$VER.tar.gz which will
            be part of the source install.  The package is scanned
	    for src/* files and if not found, additional source
	    modules are searched for and assumed to be in the
	    ./src/ directory as a result of a successfull build 
	    with install.sh

   symlinks = list of symbolic links on your system which
            should be reversed when calculating where
            the files were installed.  

            For example, if you have a symlink of 
            /usr/local -> /data/local and the install places 
            files in /usr/local.  The installwatch detection 
            will detect the actual destination which is /data/local...
            However you really want the RPM to try installing
            the files in /usr/local.
  
            Adding /usr/local to the symlinks will cause this to be 
            unfolded and result in /usr/local being used for the file 
            locations.

  Known Problems:  The installed file identification process does
           not properly identify all directories that were created.
           The effect of which is that removing the RPM with an
           rpm -e $PACKAGE will remove all of the package files,
           but not necessarily all of the directories that were
           created.
EOF
  exit 0
}

if [ ! -r $root/etc/config.cache ] ; then
  cat <<EOF 
    Unable to find $root/etc/config.cache.
EOF
  usage
fi

APACHETOOLBOX=${1:-"$PACKAGE-$VER.tar.gz"}

if [ ! -r "$APACHETOOLBOX" ] ; then
  echo "Unable to find original Apachetoolbox-$VER.tar.gz"
  usage
fi

# prepare the temporary directory used by the rpm build

MAINDIR=/tmp/apachetoolbox
rm -rf $MAINDIR
mkdir -p $MAINDIR/RPMS
mkdir -p $MAINDIR/BUILD
mkdir -p $MAINDIR/SOURCES

ln -s $APACHETOOLBOX $MAINDIR/SOURCES/
SOURCES="Source0: `basename $APACHETOOLBOX` \n"

cp etc/config.cache $MAINDIR/SOURCES/
SOURCES="${SOURCES}Source1: config.cache \n"

sn=2
SOURCEFILES="config.cache"

# If the source tarball does not include /src/* then it
# is just the install version so we need to prepare to 
# use the sources from the $root/src/* directory in 
# addition to the $APACHETOOLBOX tarball.  Otherwise
# the $APACHETOOLBOX tarball contains all sources anyway.
#
src=`zcat $APACHETOOLBOX | tar -tvf - "*$VER/src/*" 2>/dev/null`
if [ -z "$src" ] ; then
  for i in $root/src/*
  do
    if [ ! -d $i ] ; then
      ln -s $i $MAINDIR/SOURCES/
      bn=`basename $i`
      sn=`expr $sn + 1`
      SOURCES="${SOURCES}Source$sn: $bn \n"
      SOURCEFILES="$SOURCEFILES $bn"
    fi
  done
fi

cat >$MAINDIR/find-requires <<EOF
#!/bin/sh
/usr/lib/rpm/find-requires | egrep -v 'bin/perl|bin/php'
EOF
chmod +x $MAINDIR/find-requires

cat >$MAINDIR/macros <<EOF 
%_topdir        $MAINDIR
%__find_requires %{_topdir}/find-requires
%_builddir      %{_topdir}/BUILD
%_sourcedir     %{_topdir}/SOURCES
%_specdir       %{_topdir}
%_rpmdir        %{_topdir}/RPMS
%_srcrpmdir     %{_topdir}/RPMS
EOF

cat >$MAINDIR/rpmrc <<EOF 
include: /usr/lib/rpm/rpmrc
macrofiles: /usr/lib/rpm/macros:$MAINDIR/macros
EOF

SOURCES=`echo -e $SOURCES`

cat >$MAINDIR/$PACKAGE.spec <<EOF 
Summary:   $PACKAGE was used to build this custom RPM
Name:      $PACKAGE
Version:   $VER
Release:   $RPMVER
Copyright: GPL
Packager:  $PACKAGE
Group:     System Environment/Daemons
$SOURCES

%description
Apache installation built with $PACKAGE $VER 
and the buildrpm.sh script

%prep
%setup

%build

cp \$RPM_SOURCE_DIR/config.cache etc/config.cache

# If the src directory exists, then the main source package
# was $APACHETOOLBOX contains all of the source tarballs.
# Otherwise we need to create a src directory, and link in
# the sources from the RPM SOURCE directory.
if [ ! -d src ] ; then
  mkdir src
  for i in $SOURCEFILES; do
    ln -s \$RPM_SOURCE_DIR/\$i src
  done
fi

# do the build using the existing cache.
./install.sh -f

  cd apache_$APACHE
  make all

%install
  . etc/versions.conf
  . etc/defaults.conf
  . etc/functions.conf
  installwatch=$TRUE

  cd apache_$APACHE
  inst apache
  cd ..
  export SYMLINKS="$*"
EOF

cat >>$MAINDIR/$PACKAGE.spec <<\EOF 
  cat logs/*.iw | grep -v $root | perl -e '
   open(OUT,">rpmfiles.x") || die "Can not open rpmfiles.x $!";
   %links = ();
   %seendir = ();
   # Find symlinks and calculate reversal so we can figure out
   # where the application was intended to be installed,
   # rather than where it actually was installed.
   foreach $link (split(/\s+/,$ENV{"SYMLINKS"})) {
    next if (! -d $link);
    $to = readlink($link);
    if ($to !~ m:^/:) {
     $dir = $link;
     $dir =~ s:[^/]+$::;
     $to = $dir . $to;
    }
    $links{ $to } = $link if (-d $to);
   }
   while(<>) {
    @x=split;
    foreach $file (@x) {
     next if (! -f $file);
     # Handle symlink reverse substitutions.
     foreach $to (keys %links)  {
       if ($file =~ /^$to/) {
         $file =~ s/^$to/$links{$to}/;
	 last;
       }
     }
     @components = split("/",$file);
     $#components--;
     $dir = join("/",@components);
     if (!$seendir{$dir} && $dir !~ m:^/etc$:) {
       $seendir{$dir} = 1;
       print OUT "%dir $dir\n";
     }
     if ($file =~ m:/man/man[0-9]/:) {
       $file = "%doc $file";
     } elsif ($file =~ m:\.conf:) {
       $file = "%config $file";
     }
     print OUT "$file\n";
   } # foreach $file
  } # while
 ' 
 sort -u rpmfiles.x >rpmfiles.new
%post   
%postun 
%clean  
%files -f rpmfiles.new
EOF

rpm -v --rcfile $MAINDIR/rpmrc -ba $MAINDIR/$PACKAGE.spec

BRPM=$MAINDIR/RPMS/i386/$PACKAGE-$VER-$RPMVER.i386.rpm
SRPM=$MAINDIR/RPMS/$PACKAGE-$VER-$RPMVER.src.rpm

echo ""
if [ ! -r $BRPM ] ; then
  echo "*** Error ** Unable to find BINARY RPM"
  echo "             $BRPM"
else
  echo "Binary RPM: $BRPM"
fi

if [ ! -r $SRPM ] ; then
  echo "*** Error ** Unable to find SOURCE RPM"
  echo "             $SRPM"
else
  echo "Source RPM: $SRPM"
fi
echo ""