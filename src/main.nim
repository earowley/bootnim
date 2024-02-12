import efi/pci


proc main* =
  echo "Iterating over PCI/IO protocols..."
  let ps = fetchAllDevices()
  for p in ps:
    echo p
