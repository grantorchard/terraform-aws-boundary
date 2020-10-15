build {
  sources = [
    "source.amazon-ebs.boundary"
  ]

  provisioner "ansible" {
    playbook_file = "./playbooks/playbook.yaml"
  }
}

/*
  provisioner "shell" {
    inline = [
      "curl -sSL https://raw.githubusercontent.com/vmware/cloud-init-vmware-guestinfo/master/install.sh | sudo sh -"
    ]
  }
}
*/