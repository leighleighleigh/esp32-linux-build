image_name := "esp32-s3_linux"
result := justfile_directory() / "result"

before := "default_reset"
#after := "hard-reset"
after := "no_reset"

[private]
default:
  just -l -u

build:
  #!/usr/bin/env bash
  export keep_buildroot=y
  export keep_toolchain=y
  export keep_bootloader=y
  export keep_rootfs=y
  export keep_etc=y
  #unset keep_rootfs
  #unset keep_etc
  ./rebuild-esp32s3-linux-wifi.sh

flash-bootloader:
  #!/usr/bin/env bash
  PORT="$(just find-port)"
  esptool.py --chip esp32s3 -p "$PORT" -b 921600 --before={{before}} --after={{after}} write_flash 0x0 "{{result}}/bootloader.bin" 0x10000 "{{result}}/network_adapter.bin" 0x8000 "{{result}}/partition-table.bin"

flash-kernel:
  #!/usr/bin/env bash
  PORT="$(just find-port)"
  parttool.py --port "$PORT" --baud 921600 --esptool-args="before={{before}}" --esptool-args="after={{after}}" write_partition --partition-name linux --input "{{result}}/xipImage" 

flash-rootfs:
  #!/usr/bin/env bash
  PORT="$(just find-port)"
  parttool.py --port "$PORT" --baud 921600 --esptool-args="before={{before}}" --esptool-args="after={{after}}"  write_partition --partition-name rootfs --input "{{result}}/rootfs.cramfs"

flash-etc:
  #!/usr/bin/env bash
  PORT="$(just find-port)"
  parttool.py --port "$PORT" --baud 921600 --esptool-args="before={{before}}" --esptool-args="after={{after}}"  write_partition --partition-name etc --input "{{result}}/etc.jffs2"

flash:
  just flash-bootloader
  just flash-kernel
  just flash-rootfs
  just flash-etc

[private]
find-port FILTER="ttyUSB":
  #!/usr/bin/env bash
  ls /dev/{{FILTER}}[0-9] | head -n1

monitor SUFFIX="ttyUSB":
  #!/usr/bin/env nix-shell
  #!nix-shell -p lrzsz -p picocom -i bash
  PORT="$(just find-port {{SUFFIX}})"
  picocom -b 115200 --imap lfcrlf "$PORT"

