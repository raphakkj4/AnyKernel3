# AnyKernel3 Ramdisk Mod Script
# osm0sis @ xda-developers

## AnyKernel setup
# begin properties
properties() { '
kernel.string=Tequila Kernel
kernel.revision=5.4
kernel.made=@raphakk
anykernel3.made=osm0sis @ xda-developers
kernel.compiler=WEBx CLANG
message.word=enjoy :))
do.devicecheck=1
do.modules=0
do.systemless=1
do.cleanup=1
do.cleanuponabort=0
device.name1=moonstone 
device.name2=sunstone
supported.versions=12.0-15.0
supported.patchlevels=
'; } # end properties

### AnyKernel install
# boot shell variables
block=boot;
is_slot_device=auto;
no_block_display=1;

# import functions/variables and setup patching - see for reference (DO NOT REMOVE)
. tools/ak3-core.sh;

# boot install
split_boot;
flash_boot;
## end boot install
