#!/bin/bash
# FreeDOS en QEMU para Raspberry Pi - FreeDOS in QEMU for Raspberry Pi
DATA=/var/lib/freedos-kiosk
IMG="$DATA/freedos14full.img"
FLOPPY=/dev/floppy-usb
SOCK=/tmp/qemu-qmp.sock
POWEROFF_AL_SALIR=1
RUN_USER=CAMBIAR_USUARIO
RUN_UID=$(id -u "$RUN_USER")
PA_SOCK="/run/user/$RUN_UID/pulse/native"

rm -f "$SOCK"
[ -f "$IMG" ] || { echo "No existe $IMG. Ejecuta instalar.sh" >&2; exit 1; }

# Espera a que PipeWire acepte conexiones antes de lanzar QEMU - Wait for PipeWire to accept connections before launching QEMU
for i in $(seq 1 30); do
  runuser -u "$RUN_USER" -- env XDG_RUNTIME_DIR=/run/user/$RUN_UID pactl info >/dev/null 2>&1 && break
  sleep 1
done

# Salida de audio: HDMI si existe (el nombre cambia según el modelo de Pi)
for i in $(seq 1 15); do
  HDMI_SINK=$(runuser -u "$RUN_USER" -- env XDG_RUNTIME_DIR=/run/user/$RUN_UID \
    pactl list short sinks | awk '/hdmi/{print $2; exit}')
  [ -n "$HDMI_SINK" ] && break
  sleep 1
done
[ -n "$HDMI_SINK" ] && runuser -u "$RUN_USER" -- env XDG_RUNTIME_DIR=/run/user/$RUN_UID \
  pactl set-default-sink "$HDMI_SINK"

qemu-system-i386 -m 16 -cpu 486 -accel tcg,thread=multi \
  -netdev user,id=net0 \
  -device ne2k_isa,netdev=net0,iobase=0x300,irq=9 \
  -audiodev pa,id=snd0,server=$PA_SOCK \
  -audiodev pa,id=snd1,server=$PA_SOCK \
  -machine pc,pcspk-audiodev=snd1 \
  -device sb16,audiodev=snd0 \
  -device adlib,audiodev=snd0 \
  -drive file="$IMG",format=raw,if=ide,index=0,media=disk \
  -boot c \
  -drive if=floppy,index=0,format=raw,file=/dev/null \
  -device VGA \
  -display sdl,full-screen=on \
  -qmp unix:$SOCK,server,nowait &
QPID=$!

# Volúmenes fijados por nombre de nodo (los números cambian en cada arranque) - Volumes fixed by node name (numbers change with each boot)
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

# Vigilante: inserta el disquete USB en la unidad A: cuando lo detecta - Watcher: Inserts the USB floppy disk into drive A: When it detects it
(
  inserted=0
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
