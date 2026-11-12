#!/bin/bash
# flop-pi.sh - Lanza la máquina virtual en el kiosco / Launches the virtual machine in the kiosk
DATA=/var/lib/flop-pi
IMG="$DATA/freedos14full.img"   # disco por defecto / default disk
# El instalador puede cambiar IMG / The installer may change IMG
[ -f /etc/flop-pi.conf ] && . /etc/flop-pi.conf
FLOPPY=/dev/floppy-usb   # disquetera USB / USB floppy drive
SOCK=/tmp/qemu-qmp.sock  # control de QEMU / QEMU control socket
POWEROFF_AL_SALIR=1      # apagar la Pi al cerrar la máquina / power off the Pi when the machine closes
RUN_USER=primy           # usuario de la sesión de audio / user owning the audio session
RUN_UID=$(id -u "$RUN_USER")
PA_SOCK="/run/user/$RUN_UID/pulse/native"

# Formato según la extensión del disco / Disk format from its file extension
case "$IMG" in
  *.qcow2) FMT=qcow2 ;;
  *)       FMT=raw ;;
esac

rm -f "$SOCK"
[ -f "$IMG" ] || { echo "No existe $IMG. Ejecuta instalar.sh / $IMG does not exist. Run instalar.sh" >&2; exit 1; }

# Espera a que PipeWire acepte conexiones antes de lanzar QEMU / Wait for PipeWire before launching QEMU
for i in $(seq 1 30); do
  runuser -u "$RUN_USER" -- env XDG_RUNTIME_DIR=/run/user/$RUN_UID pactl info >/dev/null 2>&1 && break
  sleep 1
done

# Salida de audio: HDMI si existe (el nombre cambia según el modelo de Pi) / Audio output: HDMI if it exists (name changes with Pi model)
for i in $(seq 1 15); do
  HDMI_SINK=$(runuser -u "$RUN_USER" -- env XDG_RUNTIME_DIR=/run/user/$RUN_UID \
    pactl list short sinks | awk '/hdmi/{print $2; exit}')
  [ -n "$HDMI_SINK" ] && break
  sleep 1
done
if [ -n "$HDMI_SINK" ]; then
  runuser -u "$RUN_USER" -- env XDG_RUNTIME_DIR=/run/user/$RUN_UID \
    pactl set-default-sink "$HDMI_SINK"
fi

# Disquetera al arrancar: si hay un disquete dentro, arranca primero desde él (como en los PC antiguos)
# Floppy at boot: if a disk is inserted, it boots first (like old PCs). Otherwise, hard disk only.
FLOPPY_TAM=$(blockdev --getsize64 "$FLOPPY" 2>/dev/null || echo 0)
if [ "$FLOPPY_TAM" -gt 0 ]; then
  FLOPPY_ARG="-drive if=floppy,index=0,format=raw,file=$FLOPPY"
  BOOT_ORDEN="order=ac"
  DISQUETE_INICIAL=1
else
  FLOPPY_ARG="-drive if=floppy,index=0,format=raw,file=/dev/null"
  BOOT_ORDEN="order=c"
  DISQUETE_INICIAL=0
fi

qemu-system-i386 -m 16 -cpu 486 -accel tcg,thread=multi,tb-size=64 \
  -netdev user,id=net0 \
  -device ne2k_isa,netdev=net0,iobase=0x300,irq=9 \
  -audiodev pa,id=snd0,server=$PA_SOCK \
  -audiodev pa,id=snd1,server=$PA_SOCK \
  -machine pc,pcspk-audiodev=snd1 \
  -device sb16,audiodev=snd0 \
  -device adlib,audiodev=snd0 \
  -drive file="$IMG",format=$FMT,if=ide,index=0,media=disk \
  -boot $BOOT_ORDEN \
  $FLOPPY_ARG \
  -device VGA \
  -display sdl,full-screen=on \
  -qmp unix:$SOCK,server,nowait &
QPID=$!

# Volúmenes fijados por nombre de nodo (los números cambian en cada arranque) / Volumes set by node name (numbers change each boot)
( sleep 8; runuser -u "$RUN_USER" -- env XDG_RUNTIME_DIR=/run/user/$RUN_UID \
    wpctl set-volume @DEFAULT_AUDIO_SINK@ 1.00 ) >/dev/null 2>&1 &
( sleep 12
  for NODE in snd0 snd1; do
    ID=$(runuser -u "$RUN_USER" -- env XDG_RUNTIME_DIR=/run/user/$RUN_UID pw-dump \
         | grep -B30 "\"media.name\": \"$NODE\"" | grep '"id"' | head -n1 | tr -dc '0-9')
    [ -n "$ID" ] || continue
    if [ "$NODE" = snd0 ]; then VOL=1.00; else VOL=0.40; fi
    runuser -u "$RUN_USER" -- env XDG_RUNTIME_DIR=/run/user/$RUN_UID wpctl set-volume "$ID" "$VOL"
  done ) >/dev/null 2>&1 &

# Vigilante: inserta el disquete cuando se conecta después de arrancar, y registra si se saca
# Watcher: inserts the floppy when plugged in after boot, and tracks removals
(
  inserted=$DISQUETE_INICIAL
  while kill -0 $QPID 2>/dev/null; do
    size=$(blockdev --getsize64 $FLOPPY 2>/dev/null || echo 0)
    if [ "$size" -gt 0 ] && [ "$inserted" -eq 0 ] && [ -S "$SOCK" ]; then
      printf '%s\n' '{"execute":"qmp_capabilities"}' \
        "{\"execute\":\"human-monitor-command\",\"arguments\":{\"command-line\":\"change floppy0 $FLOPPY raw\"}}" \
        | socat - UNIX-CONNECT:$SOCK >/dev/null
      inserted=1
    elif [ "$size" -eq 0 ]; then
      inserted=0
    fi
    sleep 2
  done
) &

wait $QPID
sync
if [ "$POWEROFF_AL_SALIR" = 1 ]; then systemctl poweroff; fi
