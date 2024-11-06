qm destroy {{item.vmid}}

qm create {{item.vmid}} --memory 1024 --core 1 --name {{item.vm}} --net0 virtio,bridge=vmbr0 --scsihw virtio-scsi-pci --description "{{item.vm}}"
qm set {{item.vmid}} --virtio0 {{target_storage}}:0,import-from=/tmp/{{item.file}},format=qcow2
qm set {{item.vmid}} --boot order=virtio0
qm set {{item.vmid}} --ide2  {{target_storage}}:cloudinit
qm set {{item.vmid}} --serial0 socket --vga serial0

rm -fv /tmp/{{item.file}}
rm -fv /tmp/load_daily_cloud_{{item.name}}.sh


