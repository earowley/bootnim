import uefi

proc main* =
  echo gSystemTable.header
  echo "Hello, UEFI world!"
