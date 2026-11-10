#!/bin/bash
# instalar.sh - FreeDOS kiosk para Raspberry Pi
# Bilingual installer: Español / English
set -e

# --- Idioma / Language ---
if [ -z "$IDIOMA" ]; then
  case "${LANG:-}" in
    es*) IDIOMA=es ;;
    *)   IDIOMA=en ;;
  esac
fi
if [ "$IDIOMA" = es ]; then
  M_ROOT="Ejecuta: sudo ./instalar.sh"
  M_ARCH="Necesitas Raspberry Pi OS de 64 bits"
  M_PKG="Instalando paquetes..."
  M_IMG="Descomprimiendo la imagen de FreeDOS (puede tardar)..."
  M_CHECK="Comprobando suma SHA256..."
  M_COPY="Copiando scripts y servicio..."
  M_LINGER="Activando sesión de usuario al arrancar..."
  M_BOOT="Ocultando mensajes de arranque..."
  M_GETTY="Desactivando login en tty1..."
  M_SVC="Activando el servicio..."
  M_DONE="Instalación completada."
  M_ASK="¿Reiniciar ahora para aplicar los cambios? [s/N]: "
  M_REBOOT="Reiniciando..."
  M_LATER="Puedes reiniciar más tarde con: sudo reboot"
else
  M_ROOT="Run: sudo ./instalar.sh"
  M_ARCH="You need 64-bit Raspberry Pi OS"
  M_PKG="Installing packages..."
  M_IMG="Decompressing the FreeDOS image (this may take a while)..."
  M_CHECK="Checking SHA256 sum..."
  M_COPY="Copying scripts and service..."
  M_LINGER="Enabling user session at boot..."
  M_BOOT="Hiding boot messages..."
  M_GETTY="Disabling login on tty1..."
  M_SVC="Enabling the service..."
  M_DONE="Installation complete."
  M_ASK="Reboot now to apply changes? [y/N]: "
  M_REBOOT="Rebooting..."
  M_LATER="You can reboot later with: sudo reboot"
fi

[ "$(id -u)" -eq 0 ] || { echo "$M_ROOT"; exit 1; }
[ "$(uname -m)" = aarch64 ] || { echo "$M_ARCH"; exit 1; }

HERE="$(cd "$(dirname "$0")" && pwd)"
USUARIO="${SUDO_USER:-$(logname 2>/dev/null || echo pi)}"
UID_USUARIO=$(id -u "$USUARIO")
DATA=/var/lib/freedos-kiosk
CMD=/boot/firmware/cmdline.txt

# 1. Paquetes
echo "$M_PKG"
apt-get update
apt-get install -y qemu-system-x86 qemu-system-gui socat xinit openbox \
  x11-xserver-utils unclutter mpv pulseaudio-utils xz-utils

# 2. Imagen y vídeo
echo "$M_CHECK"
mkdir -p "$DATA"
if [ ! -f "$DATA/freedos14full.img" ]; then
  (cd "$HERE/image" && sha256sum -c SHA256SUMS)
  echo "$M_IMG"
  xz -dc "$HERE/image/freedos14full.img.xz" > "$DATA/freedos14full.img"
fi
if [ -f "$HERE/media/intro.mp4" ]; then
  cp "$HERE/media/intro.mp4" "$DATA/intro.mp4"
fi

# 3. Scripts, regla y servicio
echo "$M_COPY"
install -m 755 "$HERE/src/freedos-kiosk.sh" /usr/local/bin/freedos-kiosk.sh
install -m 755 "$HERE/src/freedos-kiosk-xinitrc" /usr/local/bin/freedos-kiosk-xinitrc
install -m 644 "$HERE/src/90-floppy-usb.rules" /etc/udev/rules.d/90-floppy-usb.rules
install -m 644 "$HERE/src/freedos-kiosk.service" /etc/systemd/system/freedos-kiosk.service
sed -i "s/^RUN_USER=.*/RUN_USER=$USUARIO/" /usr/local/bin/freedos-kiosk.sh
udevadm control --reload
udevadm trigger --subsystem-match=block

# 4. Sesión de usuario al arrancar (PipeWire disponible sin login)
echo "$M_LINGER"
loginctl enable-linger "$USUARIO"

# 5. Arranque silencioso
echo "$M_BOOT"
[ -f "$CMD.bak" ] || cp "$CMD" "$CMD.bak"
for opt in quiet loglevel=0 logo.nologo vt.global_cursor_default=0 consoleblank=0 systemd.show_status=0 fbcon=map:9; do
  grep -q -w -- "$opt" "$CMD" || sed -i "s/\$/ $opt/" "$CMD"
done
grep -q -w "console=tty3" "$CMD" || sed -i "s/console=tty1/console=tty3/" "$CMD"

# 6. Sin login en tty1
echo "$M_GETTY"
systemctl mask getty@tty1.service

# 7. Servicio
echo "$M_SVC"
systemctl daemon-reload
systemctl enable freedos-kiosk.service

# 8. Arranque en consola: sin escritorio, solo el kiosco
systemctl set-default multi-user.target
systemctl disable lightdm 2>/dev/null || true

# 9. Sin asistente de bienvenida ni arcoíris
rm -f /etc/xdg/autostart/piwiz.desktop
grep -q "^disable_splash=1" /boot/firmware/config.txt || printf "\n[all]\ndisable_splash=1\n" >> /boot/firmware/config.txt

# 10. Acelerar el arranque: lo que el kiosco no necesita
systemctl disable cloud-init-local.service cloud-init-main.service cloud-init-network.service cloud-config.service cloud-final.service 2>/dev/null || true
systemctl disable NetworkManager-wait-online.service 2>/dev/null || true

# 11. Tema de arranque sin imagen (texto, sin logo)
plymouth-set-default-theme -R text 2>/dev/null || true
echo "$M_DONE"
read -r -p "$M_ASK" RESP
case "$RESP" in
  [sSyY]*) echo "$M_REBOOT"; reboot ;;
  *)       echo "$M_LATER" ;;
esac

