qm destroy {{item.vmid}}

qm create {{item.vmid}} --memory 1024 --core 1 --name {{item.vm}} --net0 virtio,bridge=vmbr0 --scsihw virtio-scsi-pci --description "{{item.vm}}"
qm set {{item.vmid}} --scsi0 ssd-back:0,import-from=/tmp/{{item.file}},format=qcow2
qm set {{item.vmid}} --boot order=scsi0
qm set {{item.vmid}} --ide2  ssd-back:cloudinit
qm set {{item.vmid}} --serial0 socket --vga serial0

rm -fv /tmp/{{item.file}}
rm -fv /tmp/load_daily_cloud_{{item.name}}.sh


