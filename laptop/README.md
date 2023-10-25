# Provisioning

## 1. Start Live CD/USB

Once you have a live CD/USB, boot into it and start a terminal.

## 2. Download and run bootstrap

```bash
wget https://raw.githubusercontent.com/sndnv/provision/master/laptop/pull.sh
chmod +x pull.sh
. pull.sh # note: it is <dot> <space> and the script name, and NOT <dot> <slash> and the script name
./bootstrap.sh
```

## 3. Configure Installation

As part of the bootstrap process, the usual OS installer will be started. Configure it as desired, until the
partitioning step. By default, the installer will ask you to "Erase and install" but, instead, the partitioning
should be customized as follows:

### Linux Partition Boot Setup

***Based on: https://askubuntu.com/questions/733488/lvm-luks-manual-partitioned-but-issues-with-loader-init-grub/893906#893906***

* Set filesystems and mount points for all `/dev/mapper/vg_root-*` devices
* Set `/dev/sdX1` as `efi` (EFI only)
* Set `/dev/sdX2` (EFI) or `/dev/sdX1` (non-EFI) as `ext4` and `/boot`
* Set *Device for boot load installation* to be `/dev/sdX1`


## 4. Finalize boostrap and Restart

After the installation is done, the installer will ask you to restart; skip that for now so that the bootstrap process can be finalized.

## 5. Download and run provision:

```bash
wget https://raw.githubusercontent.com/sndnv/provision/master/laptop/pull.sh
chmod +x pull.sh
. pull.sh # note: it is <dot> <space> and the script name, and NOT <dot> <slash> and the script name
./provision.sh

### Windows Partition Setup:

***Based on: https://decryptingtechnology.blogspot.com/2015/09/install-windows-10-on-usb-external-hard.html***

*Advanced Install* ->  `shift+F10` ->
```
diskpart

list disk
select disk X
clean
convert gpt

create partition primary size=768
format quick fs=ntfs label="Windows RE Tools"
assign letter="T"

create partition efi size=768
format quick fs=fat32 label="System"
assign letter="S"

create partition msr size=128

create partition primary size=102400
format quick fs=ntfs label="Windows"
assign letter="W"

create partition primary size=4096
format quick fs=ntfs label="Recovery Image"
set id="<some GUID>"
gpt attributes=0x8000000000000001
assign letter="R"

exit
```

### Windows Install to USB:

```
md R:\RecoveryImage

copy C:\sources\install.wim R:\RecoveryImage\install.wim

cd X:\Windows\System32

dism /Apply-Image /ImageFile:R:\RecoveryImage\install.wim /Index:1 /ApplyDir:W:\

md T:\Recovery\WindowsRE
copy W:\Windows\System32\Recovery\winre.wim T:\Recovery\WindowsRE\winre.wim

bcdboot W:\Windows /s S: /f UEFI

W:\Windows\System32\reagentc /setosimage /path R:\RecoverImage /target W:\Windows /index 1
W:\Windows\System32\reagentc /setreimage /path T:\Recovery\WindowsRE /target W:\Windows
```
