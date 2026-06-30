### AnyKernel3 Ramdisk Mod Script
## osm0sis @ xda-developers

### AnyKernel setup
# global properties
properties() { '
kernel.string=Kraken
kernel.revision=5.4
kernel.made=Akire rs
anykernel3.made=osm0sis @ xda-developers
kernel.compiler=WeebX Clang 20.0
message.word=Thank you for install Kraken
do.devicecheck=1
do.cleanup=1
device.name1=redwood
device.name2=redwoodin
supported.versions=12.0-16.0
supported.patchlevels=
supported.vendorpatchlevels=
'; } # end properties

### AnyKernel install
## boot files attributes
boot_attributes() {
set_perm_recursive 0 0 755 644 $RAMDISK/*;
set_perm_recursive 0 0 750 750 $RAMDISK/init* $RAMDISK/sbin;
} # end attributes

# begin passthrough patch
passthrough() {
if [ ! "$(getprop persist.sys.fuse.passthrough.enable)" ]; then
 ui_print "Remounting /system as rw..."
 $home/tools/busybox mount -o rw,remount /system
 ui_print "Patching system's build prop for FUSE Passthrough..."
 patch_prop /system/build.prop "persist.sys.fuse.passthrough.enable" "true"
fi
} # end passthrough patch

## boot shell variables
BLOCK=boot;
IS_SLOT_DEVICE=1;
RAMDISK_COMPRESSION=auto;
PATCH_VBMETA_FLAG=auto;

# import functions/variables and setup patching - see for reference (DO NOT REMOVE)
. tools/ak3-core.sh && passthrough;

# boot install
dump_boot; # use split_boot to skip ramdisk unpack, e.g. for devices with init_boot ramdisk

# F2FS optimizations
ui_print "- Checking filesystem configuration...";

# Method 1: Check if kernel has F2FS support via sysfs
if ls -d /sys/fs/f2fs* 2>/dev/null | head -1 | grep -q f2fs; then
    ui_print "- Kernel has F2FS support";
    
    # Try to detect actual userdata filesystem
    USERDATA_FS=""
    USERDATA_BLOCK="/dev/block/bootdevice/by-name/userdata"
    
    # Try multiple detection methods
    if [ -b "$USERDATA_BLOCK" ]; then
        # Method A: Use blkid
        if command -v blkid >/dev/null 2>&1; then
            USERDATA_FS=$(blkid -s TYPE -o value "$USERDATA_BLOCK" 2>/dev/null)
        fi
        
        # Method B: Check fstab
        if [ -z "$USERDATA_FS" ] && [ -f "/etc/recovery.fstab" ]; then
            USERDATA_FS=$(grep -i "userdata" /etc/recovery.fstab 2>/dev/null | grep -o "f2fs" || true)
        fi
        
        # Method C: Check via tune2fs if available
        if [ -z "$USERDATA_FS" ] && command -v tune2fs >/dev/null 2>&1; then
            USERDATA_FS=$(tune2fs -l "$USERDATA_BLOCK" 2>/dev/null | grep -i "Filesystem" | awk '{print $3}' || true)
        fi
    fi
    
    ui_print "- Userdata filesystem: ${USERDATA_FS:-Unknown}";
    
    # Apply F2FS optimizations if detected or if sysfs exists
    if [ "$USERDATA_FS" = "f2fs" ] || [ "$USERDATA_FS" = "f2fs_crypt" ] || [ -z "$USERDATA_FS" ]; then
        ui_print "- Applying F2FS optimizations...";
        
        # Basic F2FS optimizations
        for f2fs_dir in /sys/fs/f2fs*; do
            if [ -d "$f2fs_dir" ]; then
                ui_print "  Optimizing: $(basename $f2fs_dir)";
                
                # ATGC (Auto Task GC) - disable for better performance
                [ -f "$f2fs_dir/atgc" ] && echo 0 > "$f2fs_dir/atgc" 2>/dev/null;
                
                # Inline crypto support
                [ -f "$f2fs_dir/inlinecrypt" ] && echo 1 > "$f2fs_dir/inlinecrypt" 2>/dev/null;
                
                # Discard/trim support
                [ -f "$f2fs_dir/discard" ] && echo "1" > "$f2fs_dir/discard" 2>/dev/null;
                
                # TCP (Tokenized Cleaning Policy) - set to foreground
                [ -f "$f2fs_dir/tc" ] && echo 1 > "$f2fs_dir/tc" 2>/dev/null;
                
                # Mode - adaptive for better UX
                [ -f "$f2fs_dir/mode" ] && echo "adaptive" > "$f2fs_dir/mode" 2>/dev/null;
                
                # IO statistics
                [ -f "$f2fs_dir/iostat_enable" ] && echo 1 > "$f2fs_dir/iostat_enable" 2>/dev/null;
            fi;
        done;
        
        # Extension list optimization
        ui_print "- Optimizing F2FS extension lists...";
        
        for list_path in $(find /sys/fs/f2fs* -name extension_list 2>/dev/null); do
            ui_print "  Processing: $(basename $(dirname $list_path))";
            
            # Clear existing list first
            echo "" > "$list_path" 2>/dev/null;
            
            # Hot extensions (frequently accessed)
            for ext in .db .xml .json .apk .dex .vdex .art .oat .odex .so .jar .prop .conf; do
                echo "[h]$ext" >> "$list_path" 2>/dev/null;
            done;
            
            # Cold extensions (temporary/cache files)
            for ext in .log .tmp .temp .cache .bak .swp .swo .pid .lock .trash; do
                echo "[c]$ext" >> "$list_path" 2>/dev/null;
            done;
            
            # Optional: Load from files if they exist
            if [ -f "$home/f2fs-hot.list" ]; then
                while read ext; do
                    [ -z "$ext" ] || [[ "$ext" == \#* ]] && continue;
                    echo "[h]$ext" >> "$list_path" 2>/dev/null;
                done < "$home/f2fs-hot.list";
            fi;
            
            if [ -f "$home/f2fs-cold.list" ]; then
                while read ext; do
                    [ -z "$ext" ] || [[ "$ext" == \#* ]] && continue;
                    echo "[c]$ext" >> "$list_path" 2>/dev/null;
                done < "$home/f2fs-cold.list";
            fi;
        done;
        
        ui_print "- F2FS optimization complete!";
    else
        ui_print "- Userdata is not F2FS ($USERDATA_FS), skipping F2FS optimizations";
    fi;
else
    ui_print "- Kernel doesn't have F2FS support, skipping F2FS optimizations";
fi;

write_boot; # use flash_boot to skip ramdisk repack, e.g. for devices with init_boot ramdisk
## end boot install

## init_boot files attributes
#init_boot_attributes() {
#set_perm_recursive 0 0 755 644 $RAMDISK/*;
#set_perm_recursive 0 0 750 750 $RAMDISK/init* $RAMDISK/sbin;
#} # end attributes

# init_boot shell variables
#BLOCK=init_boot;
#IS_SLOT_DEVICE=1;
#RAMDISK_COMPRESSION=auto;
#PATCH_VBMETA_FLAG=auto;

# reset for init_boot patching
#reset_ak;

# init_boot install
#dump_boot; # unpack ramdisk since it is the new first stage init ramdisk where overlay.d must go

#write_boot;
## end init_boot install

## vendor_kernel_boot shell variables
#BLOCK=vendor_kernel_boot;
#IS_SLOT_DEVICE=1;
#RAMDISK_COMPRESSION=auto;
#PATCH_VBMETA_FLAG=auto;

# reset for vendor_kernel_boot patching
#reset_ak;

# vendor_kernel_boot install
#split_boot; # skip unpack/repack ramdisk, e.g. for dtb on devices with hdr v4 and vendor_kernel_boot

#flash_boot;
## end vendor_kernel_boot install

## vendor_boot files attributes
vendor_boot_attributes() {
set_perm_recursive 0 0 755 644 $RAMDISK/*;
set_perm_recursive 0 0 750 750 $RAMDISK/init* $RAMDISK/sbin;
}
# end attributes

## vendor_boot shell variables
BLOCK=vendor_boot;
IS_SLOT_DEVICE=1;
RAMDISK_COMPRESSION=auto;
PATCH_VBMETA_FLAG=auto;

# reset for vendor_boot patching
reset_ak;

# vendor_boot install
#dump_boot; # use split_boot to skip ramdisk unpack, e.g. for dtb on devices with hdr v4 but no vendor_kernel_boot
split_boot;

#write_boot; # use flash_boot to skip ramdisk repack, e.g. for dtb on devices with hdr v4 but no vendor_kernel_boot
flash_boot;

## end vendor_boot install
