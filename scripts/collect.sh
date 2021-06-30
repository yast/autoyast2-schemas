#!/bin/sh
# Anas Nashif <nashif@suse.de>
# Martin Vidner <mvidner@suse.cz>
# collect RNC files, create a schema and build rng files
#

: ${TARGET:=sle-15-sp3}
SCHEMA_DIR="src/$TARGET/rnc"
DESKTOP_DIR="src/$TARGET/desktop"

: ${SRC:=src}
#: ${RNC_OUTPUT:=.}
RNC_OUTPUT="build/$TARGET/rnc"
RNG_OUTPUT="build/$TARGET/rng"

if [ ! -d $RNC_OUTPUT ]
then
   mkdir -p $RNC_OUTPUT
fi

if [ ! -d $RNG_OUTPUT ]
then
   mkdir -p $RNG_OUTPUT
fi

COMMON=$SCHEMA_DIR/common.rnc
TEMPLATE=src/$TARGET/templ/profile.rnc.templ

rm -f $RNC_OUTPUT/includes.rnc
cp $COMMON $RNC_OUTPUT
cp $SCHEMA_DIR/classes-use.rnc $RNC_OUTPUT
cp $SCHEMA_DIR/runlevels.rnc $RNC_OUTPUT
cp $SCHEMA_DIR/profile-misc.rnc $RNC_OUTPUT

# Formerly the elements were sorted in these 2 categories but that
# distinction is obsolete except in this script
install=""
configure=""
# NOTE: 'classes' and 'runlevel' are hard-coded in 'classes-use.rnc' and 'runlevels.rnc'
known=" | classes | runlevel"

# check all desktop files

for desktop in `find $DESKTOP_DIR -name '*.desktop' | LC_ALL=C sort`; do
    unset X_SuSE_YaST_AutoInstSchema
    unset X_SuSE_YaST_AutoInstResource
    unset X_SuSE_YaST_AutoInstPath
    unset X_SuSE_YaST_AutoInstOptional

    X_SuSE_YaST_AutoInstSchema=`grep "^X-SuSE-YaST-AutoInstSchema" $desktop`
    X_SuSE_YaST_AutoInstSchema=${X_SuSE_YaST_AutoInstSchema##*=}
    X_SuSE_YaST_AutoInstResource=`grep "^X-SuSE-YaST-AutoInstResource=" $desktop` # do not take AutoInstResourceAliases
    X_SuSE_YaST_AutoInstResource=${X_SuSE_YaST_AutoInstResource##*=}
    X_SuSE_YaST_AutoInstPath=`grep "^X-SuSE-YaST-AutoInstPath" $desktop`
    X_SuSE_YaST_AutoInstPath=${X_SuSE_YaST_AutoInstPath##*=}
    X_SuSE_YaST_AutoInstOptional=`grep "^X-SuSE-YaST-AutoInstOptional" $desktop`
    X_SuSE_YaST_AutoInstOptional=${X_SuSE_YaST_AutoInstOptional##*=}

    if [ -z "$X_SuSE_YaST_AutoInstResource" ]; then
        resource=`basename $desktop .desktop`
        resource="FLAG__X_SuSE_YaST_AutoInstResource__not_set__in_$resource"
    else
        resource=$X_SuSE_YaST_AutoInstResource
        known="$known | $resource"
    fi

    # HACK: avoid creating a separate desktop file
    # for user_defaults (#215249#c7)
    if [ "$resource" = "users" ]; then
        resource="user_defaults? & groups? & login_settings? & users"
        known="$known | user_defaults | groups | login_settings"
    fi

    # same hack as for users. pxe.rnc is part of autoyast but has no client
    if [ "$resource" = "general" ]; then
        resource="general? & pxe"
        known="$known | general | pxe"
        cp  $SCHEMA_DIR/pxe.rnc $RNC_OUTPUT
        echo "include 'pxe.rnc' # autoyast2" >> $RNC_OUTPUT/includes.rnc
    fi

    if [ ! -z "${X_SuSE_YaST_AutoInstSchema}" ]; then

        cp  $SCHEMA_DIR/${X_SuSE_YaST_AutoInstSchema} $RNC_OUTPUT
        
        echo "include '${X_SuSE_YaST_AutoInstSchema}'" >> $RNC_OUTPUT/includes.rnc

        if [ -z "$X_SuSE_YaST_AutoInstOptional" -o "$X_SuSE_YaST_AutoInstOptional" = "true" ]; then
	    optional="?"
	else
	    optional=""
	fi

	if [ "$X_SuSE_YaST_AutoInstPath" = "install" ]; then
	    install="$install & $resource$optional"
	else
	    configure="$configure & $resource$optional"
        fi
    fi

done

# remove the initial connector
install="${install# & }"
configure="${configure# & }"
known="${known# | }"

echo >&2 "install:   $install"
echo >&2 "configure: $configure"
echo >&2 "known:     $known"

# escape the connector for sed: & -> \&
install="${install//&/\\&}"
configure="${configure//&/\\&}"

# add those components we have found
sed -e "s/CONFIGURE_RESOURCE/${configure}/" \
    -e "s/INSTALL_RESOURCE/${install}/" \
    -e "s/KNOWN_RESOURCE/${known}/" \
    $TEMPLATE > $RNC_OUTPUT/profile.rnc

#
# build rng files
#
for rnc in $RNC_OUTPUT/*.rnc
do
    echo "Converting $rnc ..."
    trang "$rnc" "$RNG_OUTPUT/$(basename "$rnc" .rnc).rng"
done
