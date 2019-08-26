#!/bin/sh
## postinstall

##########################
# Pre-Installation #######
##########################

# Make sure we have the requisite software
echo "[lups-linux] installing packages"
install="sudo dnf install -y"
$install cups hplip

# Install the smbclient backend, necessary for
#  proper authentication
# (http://willem.engen.nl/projects/cupssmb/smbc)
echo "[lups-linux] creating smbclient backend"
smbc_backend="/usr/lib/cups/backend/smbc"
sudo tee $smbc_backend > /dev/null <<EOF
#!/bin/sh

if [ "$1" = "" ]; then
   # list supported output types
   echo 'network smbc "Unknown" "smbclient"'
   exit 0
fi

job="$1"
account="$2"
title="$3"
numcopies="$4"
options="$5"
filename="$6"

# read from stdin if no file given
if [ "$filename" = "" ]; then
	filename=-
fi

# strip protocol from printer URI
printer=`echo "${DEVICE_URI}" | sed 's/^.*://'`

# and print using smbclient
echo "NOTICE: smbclient -c \"print ${filename}\" \"${printer}\"" 1>&2

errtxt=`smbclient -N -A /etc/samba/printing.auth -c "print ${filename}" "${printer}" 2>&1`
ret=${?}

# Handle errors
#   see backend(7) for error codes

# log message
if [ "$ret" = "0" ]; then
	echo "$errtxt" | sed 's/^/NOTICE: /' 1>&2
else
	echo "$errtxt" | sed 's/^/ERROR: /' 1>&2
fi

# "NT_STATUS_LOGON_FAILURE" -> CUPS_BACKEND_AUTH_REQUIRED
echo "$errtxt" | grep -i 'LOGON_FAILURE' >/dev/null && return 2
# "Unable to open credentials file!" -> CUPS_BACKEND_AUTH_REQUIRED
echo "$errtxt" | grep -i 'credentials' >/dev/null && return 2
# "NT_STATUS_BAD_NETWORK_NAME" -> CUPS_BACKEND_STOP
echo "$errtxt" | grep -i 'BAD_NETWORK_NAME' >/dev/null && return 4

# something went wrong, don't know what -> CUPS_BACKEND_FAILED
[ "$ret" != "0" ] && return 1

# success! -> CUPS_BACKEND_OK
return 0

EOF

# Set proper backend permissions
sudo chown root.root $smbc_backend
sudo chmod 700 $smbc_backend

###########################
# Monochrome Printer #####
###########################
echo "[lups-linux] adding HP-B&W"

printername="HP-B&W"
location="HP BW Printers"
gui_display_name="HP-B&W"
address="smbc://lups01/HP-B&W"
driver_ppd="/usr/share/ppd/HP/hp-laserjet_mfp_m725-ps.ppd.gz"

# Populate these options if you want to set specific options for the printer,
#  e.g. duplexing installed, etc.
option_1="HPOption_Tray3=HP500SheetInputTray"
option_2="HPOption_Tray4=HP500SheetInputTray"
option_3="HPOption_Duplexer=True"
option_4="HPOption_SS_BM_Finisher_Mode=StackerMode"
option_5="printer-op-policy=authenticated"

### Printer Install ###
# In case we are making changes to a printer we need to remove an existing queue if it exists.
/usr/bin/lpstat -p $printername 2>/dev/null
if [ $? -eq 0 ]; then
        /usr/sbin/lpadmin -x $printername
fi

# Now we can install the printer.
/usr/sbin/lpadmin \
        -p "$printername" \
        -L "$location" \
        -D "$gui_display_name" \
        -v "$address" \
        -P "$driver_ppd" \
        -o "$option_1" \
        -o "$option_2" \
        -o "$option_3" \
        -o "$option_4" \
        -o "$option_5" \
        -o "$option_6" \
        -o auth-info-required=username,password \
        -o printer-is-shared=false \
        -E

# Enable and start the printers on the system (after adding the printer initially it is paused).
/usr/sbin/cupsenable $(lpstat -p | grep -w "printer" | awk '{print$2}')

#################
# Color Printer #
#################
echo "[lups-linux] adding HP-Color"

printername="HP-Color"
location="HP Color Printers"
gui_display_name="HP-Color"
address="smbc://lups01/HP-Color"
driver_ppd="/usr/share/ppd/HP/hp-color_laserjet_flow_mfp_m880-ps.ppd.gz"

# Populate these options if you want to set specific options for the printer,
#  e.g. duplexing installed, etc.
option_1="HPOption_Tray3=HP500SheetInputTray"
option_2="HPOption_Tray4=HP500SheetInputTray"
option_3="HPOption_Duplexer=True"
option_4="HPOption_SS_BM_Finisher_Mode=StackerMode"
option_5="printer-op-policy=authenticated"

### Printer Install ###
# In case we are making changes to a printer we need to remove an existing queue if it exists.
/usr/bin/lpstat -p $printername 2>/dev/null
if [ $? -eq 0 ]; then
        /usr/sbin/lpadmin -x $printername
fi

# Now we can install the printer.
/usr/sbin/lpadmin \
        -p "$printername" \
        -L "$location" \
        -D "$gui_display_name" \
        -v "$address" \
        -P "$driver_ppd" \
        -o "$option_1" \
        -o "$option_2" \
        -o "$option_3" \
        -o "$option_4" \
        -o "$option_5" \
        -o auth-info-required=username,password \
        -o printer-is-shared=false \
        -E
# Enable and start the printers on the system (after adding the printer initially it is paused).
/usr/sbin/cupsenable $(lpstat -p | grep -w "printer" | awk '{print$2}')

exit 0		## Success
exit 1		## Failure
