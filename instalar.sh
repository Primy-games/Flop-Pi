#!/bin/bash
# instalar.sh - Flop-Pi: kiosco de máquina virtual para Raspberry Pi / Flop-Pi: virtual machine kiosk for Raspberry Pi
# Instalador bilingüe / Bilingual installer: Español / English
set -e

# --- Idioma / Language ---
if [ -z "$IDIOMA" ]; then
  case "${LANG:-}" in
    es*) IDIOMA=es ;;
    *)   IDIOMA=en ;;
  esac
fi

# t "texto en español" "text in English" / t "Spanish text" "English text"
t() { if [ "$IDIOMA" = es ]; then printf '%s' "$1"; else printf '%s' "$2"; fi; }

[ "$(id -u)" -eq 0 ] || { echo "$(t "Ejecuta: sudo ./instalar.sh" "Run: sudo ./instalar.sh")"; exit 1; }
[ "$(uname -m)" = aarch64 ] || { echo "$(t "Necesitas Raspberry Pi OS de 64 bits" "You need 64-bit Raspberry Pi OS")"; exit 1; }

HERE="$(cd "$(dirname "$0")" && pwd)"
USUARIO="${SUDO_USER:-$(logname 2>/dev/null || echo pi)}"
DATA=/var/lib/flop-pi
CMD=/boot/firmware/cmdline.txt
CONF=/etc/flop-pi.conf
TAM_IMAGEN_GB=16   # tamaño de la imagen preparada / size of the prepared image
RESERVA_GB=1       # espacio libre que se deja al sistema / free space left for the system

espacio_libre_gb() { df -BG --output=avail "$1" | tail -n1 | tr -dc '0-9'; }

# 1. Paquetes / Packages
echo "$(t "Instalando paquetes..." "Installing packages...")"
apt-get update
apt-get install -y qemu-system-x86 qemu-system-gui qemu-utils socat xinit openbox \
  x11-xserver-utils unclutter mpv pulseaudio-utils xz-utils

# 2. Disco: conservar el existente, imagen preparada o disco vacío / Disk: keep existing, prepared image or empty disk
mkdir -p "$DATA"

EXISTENTE=""
for f in "$DATA"/*.img "$DATA"/*.qcow2; do   # busca discos ya creados / look for disks already created
  if [ -f "$f" ]; then EXISTENTE="$f"; break; fi
done

IMG_FINAL="$EXISTENTE"
if [ -n "$EXISTENTE" ]; then
  echo "$(t "Ya existe un disco en $EXISTENTE" "A disk already exists at $EXISTENTE")"
  read -r -p "$(t "¿Conservarlo? [S/n]: " "Keep it? [Y/n]: ")" RESP
  case "$RESP" in
    [nN]*)   # el usuario quiere sustituirlo / the user wants to replace it
      read -r -p "$(t "Se borrará $EXISTENTE con todo lo que tiene dentro. ¿Continuar? [s/N]: " "$EXISTENTE and everything on it will be deleted. Continue? [y/N]: ")" CONFIRMA
      case "$CONFIRMA" in
        [sSyY]*) rm -f "$EXISTENTE"; IMG_FINAL="" ;;
      esac
      ;;
  esac
fi

if [ -z "$IMG_FINAL" ]; then
  LIBRE=$(espacio_libre_gb "$DATA")
  echo "$(t "Espacio libre en la tarjeta: ${LIBRE} GB" "Free space on the card: ${LIBRE} GB")"
  echo "$(t "  1) Imagen preparada, con el sistema ya instalado (ocupa ${TAM_IMAGEN_GB} GB)" "  1) Prepared image, with the system already installed (takes ${TAM_IMAGEN_GB} GB)")"
  echo "$(t "  2) Disco vacío: tú eliges el tamaño e instalas el sistema" "  2) Empty disk: you choose the size and install the system yourself")"
  read -r -p "$(t "Elige [1/2] (Enter = 1): " "Choose [1/2] (Enter = 1): ")" OPCION

  if [ "$OPCION" = 2 ]; then
    MAX_GB=$((LIBRE - RESERVA_GB))   # máximo que cabe con la reserva / maximum that fits with the reserve
    if [ "$MAX_GB" -lt 1 ]; then
      echo "$(t "No hay espacio suficiente para un disco vacío." "Not enough space for an empty disk.")"
      exit 1
    fi
    while true; do
      read -r -p "$(t "Tamaño del disco en GB (máximo $MAX_GB): " "Disk size in GB (maximum $MAX_GB): ")" TAM
      if [[ "$TAM" =~ ^[0-9]+$ ]] && [ "$TAM" -ge 1 ] && [ "$TAM" -le "$MAX_GB" ]; then
        break
      fi
      echo "$(t "Tamaño no válido. Debe estar entre 1 y $MAX_GB GB." "Invalid size. It must be between 1 and $MAX_GB GB.")"
    done

    echo "$(t "Formato del disco:" "Disk format:")"
    echo "$(t "  1) raw   - el más simple y rápido; ocupa lo que se escribe. Recomendado." "  1) raw   - simplest and fastest; uses what is written. Recommended.")"
    echo "$(t "  2) qcow2 - permite instantáneas para volver atrás; algo más lento y complejo." "  2) qcow2 - allows snapshots to go back; a bit slower and more complex.")"
    read -r -p "$(t "Elige [1/2] (Enter = 1): " "Choose [1/2] (Enter = 1): ")" FORMATO
    if [ "$FORMATO" = 2 ]; then
      IMG_FINAL="$DATA/disco.qcow2"
      qemu-img create -f qcow2 "$IMG_FINAL" "${TAM}G"   # disperso: ocupa casi nada al principio / sparse: uses almost no space at first
    else
      IMG_FINAL="$DATA/disco.img"
      truncate -s "${TAM}G" "$IMG_FINAL"   # disperso: ocupa casi nada al principio / sparse: uses almost no space at first
    fi
    echo "$(t "Disco creado: $IMG_FINAL" "Disk created: $IMG_FINAL")"
  else
    NECESARIO=$((TAM_IMAGEN_GB + RESERVA_GB))
    if [ "$LIBRE" -lt "$NECESARIO" ]; then
      echo "$(t "Espacio insuficiente: hacen falta ${NECESARIO} GB libres y hay ${LIBRE} GB." "Not enough space: you need ${NECESARIO} GB free and there are ${LIBRE} GB.")"
      exit 1
    fi
    (cd "$HERE/image" && sha256sum -c SHA256SUMS)   # comprueba la integridad / checks integrity
    echo "$(t "Descomprimiendo la imagen preparada (puede tardar)..." "Decompressing the prepared image (this may take a while)...")"
    IMG_FINAL="$DATA/freedos14full.img"
    xz -dc "$HERE/image/freedos14full.img.xz" > "$IMG_FINAL"
  fi
fi

if [ -f "$HERE/media/intro.mp4" ]; then   # vídeo de introducción opcional / optional intro video
  cp "$HERE/media/intro.mp4" "$DATA/intro.mp4"
fi

# El script lee la ruta del disco desde este fichero / The script reads the disk path from this file
echo "IMG=\"$IMG_FINAL\"" > "$CONF"
chmod 644 "$CONF"

# 3. Scripts, regla, servicio y Openbox / Scripts, rule, service and Openbox
echo "$(t "Copiando scripts y servicio..." "Copying scripts and service...")"
install -m 755 "$HERE/src/flop-pi.sh" /usr/local/bin/flop-pi.sh
install -m 755 "$HERE/src/flop-pi-xinitrc" /usr/local/bin/flop-pi-xinitrc
install -m 644 "$HERE/src/90-floppy-usb.rules" /etc/udev/rules.d/90-floppy-usb.rules
install -m 644 "$HERE/src/flop-pi.service" /etc/systemd/system/flop-pi.service
sed -i "s/^RUN_USER=.*/RUN_USER=$USUARIO/" /usr/local/bin/flop-pi.sh   # usuario que ejecuta el instalador / user running the installer
udevadm control --reload
udevadm trigger --subsystem-match=block

# 3b. Openbox sin atajos de teclado ni de ratón / Openbox without keyboard or mouse shortcuts
mkdir -p /root/.config/openbox   # el servicio corre como root / the service runs as root
if [ -f /root/.config/openbox/rc.xml ] && [ ! -f /root/.config/openbox/rc.xml.bak ]; then
  cp /root/.config/openbox/rc.xml /root/.config/openbox/rc.xml.bak
fi
install -m 644 "$HERE/src/openbox-rc.xml" /root/.config/openbox/rc.xml

# 4. Sesión de usuario al arrancar / User session at boot
echo "$(t "Activando sesión de usuario al arrancar..." "Enabling user session at boot...")"
loginctl enable-linger "$USUARIO"   # PipeWire disponible sin login / PipeWire available without login

# 5. Arranque silencioso / Silent boot
echo "$(t "Ocultando mensajes de arranque..." "Hiding boot messages...")"
[ -f "$CMD.bak" ] || cp "$CMD" "$CMD.bak"   # copia de seguridad, solo la primera vez / backup, first time only
for opt in quiet loglevel=0 logo.nologo vt.global_cursor_default=0 consoleblank=0 systemd.show_status=0 fbcon=map:9; do
  grep -q -w -- "$opt" "$CMD" || sed -i "s/\$/ $opt/" "$CMD"
done
grep -q -w "console=tty3" "$CMD" || sed -i "s/console=tty1/console=tty3/" "$CMD"

# 6. Sin login en tty1 / No login on tty1
echo "$(t "Desactivando login en tty1..." "Disabling login on tty1...")"
systemctl mask getty@tty1.service

# 7. Servicio / Service
echo "$(t "Activando el servicio..." "Enabling the service...")"
systemctl daemon-reload
systemctl enable flop-pi.service

# 8. Arranque en consola: sin escritorio, solo el kiosco / Console boot: no desktop, only the kiosk
systemctl set-default multi-user.target
systemctl disable lightdm 2>/dev/null || true

# 9. Sin asistente de bienvenida ni arcoíris / No welcome wizard, no rainbow screen
rm -f /etc/xdg/autostart/piwiz.desktop
grep -q "^disable_splash=1" /boot/firmware/config.txt || printf "\n[all]\ndisable_splash=1\n" >> /boot/firmware/config.txt

# 10. Acelerar el arranque / Faster boot
systemctl disable cloud-init-local.service cloud-init-main.service cloud-init-network.service cloud-config.service cloud-final.service 2>/dev/null || true
systemctl disable NetworkManager-wait-online.service 2>/dev/null || true

# 11. Tema de arranque sin imagen / Boot theme without image
plymouth-set-default-theme -R text 2>/dev/null || true

echo "$(t "Instalación completada." "Installation complete.")"
read -r -p "$(t "¿Reiniciar ahora para aplicar los cambios? [s/N]: " "Reboot now to apply changes? [y/N]: ")" RESP
case "$RESP" in
  [sSyY]*) echo "$(t "Reiniciando..." "Rebooting...")"; reboot ;;
  *)       echo "$(t "Puedes reiniciar más tarde con: sudo reboot" "You can reboot later with: sudo reboot")" ;;
esac
