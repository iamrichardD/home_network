## 1. Create a dedicated Role with specific privileges
```bash
pveum role add Terraform -privs "VM.Allocate, VM.Audit, VM.Config.Network, VM.Config.Disk, VM.Config.CPU, VM.Config.Memory, Datastore.AllocateSpace, Datastore.Audit, Sys.Console, Sys.Audit"
```

## 2. Create the User
```bash
pveum user add terraform-prov@pve --password YOUR_STRONG_PASSWORD
```

## 3. Associate the User with the Role
```bash
pveum aclmod / -user terraform-prov@pve -role Terraform
````

## 4. Generate the API Token (Save the ID and Secret!)
```bash
pveum user token add terraform-prov@pve tao-scanner --privsep=0
```
