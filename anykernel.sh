### AnyKernel3 installer for Kraken 6.12 on Xiaomi redwood

properties() { '
kernel.string=Kraken 6.12 for redwood
do.devicecheck=1
do.modules=0
do.systemless=0
do.cleanup=1
do.cleanuponabort=0
device.name1=redwood
device.name2=redwoodin
supported.versions=16-17
supported.patchlevels=
supported.vendorpatchlevels=
'; }

boot_attributes() {
  set_perm_recursive 0 0 755 644 "$RAMDISK"/*;
  set_perm_recursive 0 0 750 750 "$RAMDISK"/init* "$RAMDISK"/sbin;
}

vendor_boot_attributes() {
  set_perm_recursive 0 0 755 644 "$RAMDISK"/*;
  set_perm_recursive 0 0 750 750 "$RAMDISK"/init* "$RAMDISK"/sbin;
}

BLOCK=boot;
IS_SLOT_DEVICE=1;
RAMDISK_COMPRESSION=auto;
PATCH_VBMETA_FLAG=auto;

. tools/ak3-core.sh;

ui_print " " "Kraken 6.12 redwood installer";
ui_print "Patching the active boot slot...";
cp -f "$AKHOME/payload/Image" "$AKHOME/Image" || abort "Missing kernel Image";
dump_boot;
write_boot;
rm -f "$AKHOME/Image";

BLOCK=vendor_boot;
IS_SLOT_DEVICE=1;
RAMDISK_COMPRESSION=auto;
PATCH_VBMETA_FLAG=auto;

reset_ak;

ui_print "Patching vendor_boot DTB and matching 6.12 modules...";
dump_boot;

rm -rf "$RAMDISK/lib/modules";
mkdir -p "$RAMDISK/lib/modules" || abort "Cannot create vendor ramdisk module directory";
cp -af "$AKHOME/payload/modules"/* "$RAMDISK/lib/modules/" || abort "Cannot install 6.12 modules";
set_perm_recursive 0 0 755 644 "$RAMDISK/lib/modules";

cp -f "$AKHOME/payload/dtb" "$AKHOME/dtb" || abort "Missing redwood DTB";
cp -f "$AKHOME/payload/dtbo.img" "$AKHOME/dtbo.img" || abort "Missing redwood DTBO image";

write_boot;

module_count=$(wc -l < "$AKHOME/payload/modules/modules.load" 2>/dev/null);
[ "$module_count" ] || module_count="matching";
ui_print " " "Installed Image, DTB, DTBO and $module_count modules.";
ui_print "If boot fails, restore boot, vendor_boot and dtbo from the same slot.";
