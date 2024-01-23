qm destroy {{item.vmid}}
qm create {{item.vmid}} --memory 1024 --core 1 --name {{item.vm}} --net0 virtio,bridge=vmbr0 --description "{{item.vm}}"
qm importdisk {{item.vmid}} /tmp/{{item.file}} local-lvm
qm set {{item.vmid}} --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-{{item.vmid}}-disk-0
qm set {{item.vmid}} --boot c --bootdisk scsi0
qm set {{item.vmid}} --ide2 local-lvm:cloudinit
qm set {{item.vmid}} --serial0 socket --vga serial0
rm -fv /tmp/{{item.file}}
rm -fv /tmp/load_daily_cloud.sh