build {
  sources = [
    "source.amazon-ebs.boundary"
  ]

	hcp_packer_registry {
		slug = "boundary"
		description = "Boundary base image"
		labels = {
			"owner" = "Grant Orchard"
			"application" = "boundary"
			"version" = "0.5"
		}
	}

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