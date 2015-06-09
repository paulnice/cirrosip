export ARCH=i386

br_ver="2015.05"
mkdir -p ../download
ln -snf ../download download
( cd download && wget http://buildroot.uclibc.org/downloads/buildroot-${br_ver}.tar.gz )
tar -xvf download/buildroot-${br_ver}.tar.gz
ln -snf buildroot-${br_ver} buildroot

./bin/mkcabundle > src/etc/ssl/certs/ca-certificates.crt

( cd buildroot && QUILT_PATCHES=$PWD/../patches-buildroot quilt push -a )

make ARCH=i386 br-source

make ARCH=i386 OUT_D=$PWD/output/i386

kver="3.19.0-20.20~14.04.1"
./bin/grab-kernels "$kver"

./bin/bundle -v --arch=$ARCH output/$ARCH/rootfs.tar download/kernel-$ARCH.deb output/$ARCH/images

VERSION=current
CURDIR=$(pwd)
export KERNEL=$CURDIR/images/cirros-$VERSION-$ARCH-vmlinuz
export INITRD=$CURDIR/images/cirros-$VERSION-$ARCH-initrd
BLANK=images/cirros-$VERSION-$ARCH-blank.img

mkdir -p images
chown ps:ps images
mv output/i386/images/kernel $KERNEL
mv output/i386/images/initramfs $INITRD
mv output/i386/images/blank.img $BLANK

export VM_NAME=cirros$$

IMAGES_BASE=$CURDIR/images
cp $BLANK images/$VM_NAME.img
export VM_DISK=$IMAGES_BASE/$VM_NAME.img
chown ps:ps $IMAGES_BASE/$VM_NAME.img
su -c 'virt-install -r 256 \
  -n $VM_NAME \
  --vcpus=1 \
  --import \
  --autostart \
  --memballoon virtio \
  --network bridge=virbr0 \
  --boot kernel=$KERNEL,initrd=$INITRD,kernel_args="console=/dev/ttyS0 ds=nocloud" \
  --disk $VM_DISK \
  --noautoconsole \
  --serial tcp,host=127.0.0.1:5701,mode=bind,protocol=telnet' ps

telnet 127.0.0.1 5701

