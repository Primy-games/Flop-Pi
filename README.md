## Flop-Py: ¿Qué es y cuál es su filosofía?
Flop-Py nace de la nostalgia por recuperar la experiencia real de los primeros equipos x86: el traqueteo de las disqueteras, las limitaciones de almacenamiento y el inconfundible sonido de las tarjetas Sound Blaster.
Pero Flop-Py no quiere limitarse a imitar aquella época. Quiere que vuelvas a vivirla.
El proyecto está diseñado para trabajar con disquetes físicos mediante una unidad USB (prepárate, porque necesitarás disquetes reales), conservando tanto sus virtudes como sus inconvenientes. Nada de atajos que eliminen la experiencia original. Todo ello aprovechando la conectividad y el reducido tamaño de equipos como Raspberry Pi, porque, seamos sinceros, el espacio no sobra.
Aquí no encontrarás facilidades innecesarias.
Si buscas un emulador moderno que te permita utilizar unidades virtuales, montar imágenes ISO o disponer de todas esas comodidades a las que estamos acostumbrados hoy en día, probablemente este no sea tu sitio.
Flop-Py tiene otra filosofía: recuperar la experiencia de sentarse delante de un ordenador de mediados de los años 80. Eso significa volver a pelearse con el CONFIG.SYS y el AUTOEXEC.BAT, ajustar la memoria convencional, lidiar con las limitaciones del hardware y, por supuesto, esperar pacientemente a que la disquetera termine su trabajo.
Porque aquí los tiempos de carga no se simulan: se sufren y se disfrutan.
Flop-Py no está pensado para todo el mundo. Es un proyecto para quienes disfrutaron de aquella informática, para los curiosos que quieren descubrir cómo funcionaba realmente y para los que consideran que configurar un ordenador era casi tan divertido como utilizarlo.
Si alguna vez has arrancado un ordenador desde un disquete de 3½ pulgadas, probablemente ya sabes de qué estamos hablando.
La informática de antes. Con las limitaciones de antes. Y sin pedir disculpas por ello.

Bienvenido a Flop-Py.


---

## Español

### Requisitos

- Raspberry Pi 3 Model B, 3B+ o 4/400. (El modelo 3B es la más lenta y tiene 1 GB de RAM lo que la hace la menos aconsjable patra vivir la experiencia mas real) .
- Raspberry Pi OS de 64 bits, recién instalado, con conexión a Internet.
- Tarjeta microSD de 32 GB.
- Disquetera USB (probada: NEC USB UF000x).

### Instalación

```bash
git clone https://github.com/USUARIO/freedos-kiosk.git
cd freedos-kiosk
sudo ./instalar.sh
```

El instalador usa el usuario que lo ejecuta (`SUDO_USER`) como `RUN_USER` del script. Al final pregunta si quieres reiniciar. Si no, reinicia tú más tarde con `sudo reboot`.

Para forzar el idioma del instalador: `sudo IDIOMA=es ./instalar.sh` o `sudo IDIOMA=en ./instalar.sh`.

### Uso

- **Disquetes:** conecta la disquetera USB con un disco dentro. Se inserta automáticamente en A:. Al cambiar de disco, FreeDOS lee el nuevo sin reiniciar.
- **Ratón:** se captura al hacer clic en la ventana. Para soltarlo: Ctrl+Alt+G.
- **Pantalla completa:** Ctrl+Alt+F.
- **Apagar:** escribe `SHUTDOWN` dentro de FreeDOS. Al cerrar QEMU, la Pi se apaga por defecto (ver "Personalizar" para cambiarlo).

**Importante:** no apagues la Pi tirando del cable mientras FreeDOS está en marcha. Sal siempre con `SHUTDOWN`.

### Estructura del proyecto

```
freedos-kiosk/
├── instalar.sh                  Instalador (bilingüe)
├── README.md                    Este fichero
├── src/
│   ├── freedos-kiosk.sh         Lanza QEMU, volúmenes, salida HDMI y vigilante de disquetes
│   ├── freedos-kiosk-xinitrc    Sesión X: vídeo de introducción y lanzamiento
│   ├── freedos-kiosk.service    Servicio de systemd
│   └── 90-floppy-usb.rules      Regla udev: crea /dev/floppy-usb
├── media/
│   └── intro.mp4                Vídeo de introducción (opcional)
└── image/
    ├── freedos14full.img.xz     Imagen de FreeDOS comprimida
    └── SHA256SUMS               Suma de verificación de la imagen
```

### Qué instala y qué cambia el sistema

**Paquetes:** qemu-system-x86, qemu-system-gui, socat, xinit, openbox, x11-xserver-utils, unclutter, mpv, pulseaudio-utils, xz-utils.

**Archivos del sistema:**

- `/usr/local/bin/freedos-kiosk.sh` y `/usr/local/bin/freedos-kiosk-xinitrc`
- `/etc/systemd/system/freedos-kiosk.service`
- `/etc/udev/rules.d/90-floppy-usb.rules`
- `/var/lib/freedos-kiosk/` (imagen y vídeo)
- `/boot/firmware/cmdline.txt` (copia de seguridad en `cmdline.txt.bak`)
- `/boot/firmware/config.txt`: añade `disable_splash=1` dentro de `[all]`, para no mostrar el arcoíris al arrancar.

**Cambios de sistema:**

- `getty@tty1` queda enmascarado (sin login en pantalla).
- El destino por defecto pasa a `multi-user.target` y se desactiva `lightdm`.
- Se desactivan cloud-init y `NetworkManager-wait-online` para acelerar el arranque. No afecta a la red.
- Se borra el asistente de bienvenida (`piwiz.desktop`).
- `loginctl enable-linger` para tu usuario, para que PipeWire esté disponible al arrancar.

### Personalizar

- **Volúmenes:** en `src/freedos-kiosk.sh`, la sección de volúmenes. La tarjeta (snd0) y el altavoz (snd1) se buscan por nombre en cada arranque. Valores actuales: sink 1.00, tarjeta 1.00, altavoz 0.40. Ajústalos si tu Pi suena distinto.
- **Apagado al salir de FreeDOS:** en `src/freedos-kiosk.sh`, `POWEROFF_AL_SALIR=1` apaga la Pi al cerrar QEMU. Cámbialo a `0` para que siga encendida.
- **Memoria, CPU, dispositivos:** en la línea `qemu-system-i386` de ese mismo script (`-m`, `-cpu`, `-accel`, `-device`).
- **Salida HDMI del audio:** el script busca automáticamente la salida HDMI de PipeWire al arrancar y la usa como predeterminada si existe. Si quieres otra salida (por ejemplo el jack de 3,5 mm), cambia la línea `pactl set-default-sink` o usa `wpctl set-default` manualmente.
- **Vídeo de introducción:** cambia `media/intro.mp4` por otro antes de instalar, o elimínalo para no mostrarlo.

### Overclock (opcional, no incluido en el instalador)

El instalador no toca la frecuencia de la CPU. Si quieres probar un overclock, añádelo a mano en `/boot/firmware/config.txt`, en la sección `[all]`:

```
arm_freq=1300
```

- Los valores que sirven dependen del modelo y de la alimentación. La Pi 3 Model B va de fábrica a 1,2 GHz.
- Antes de subir la frecuencia, comprueba la alimentación: `vcgencmd get_throttled` debe dar `0x0`. Un valor distinto indica caídas de tensión o limitación térmica.
- Si la Pi no arranca tras cambiarlo, mantén Shift durante el arranque para desactivar el overclock, o quita las líneas desde el PC montando la tarjeta.

### Usar otra imagen de sistema

La imagen se llama `freedos14full.img` y está en `/var/lib/freedos-kiosk/`. Para usar otra:

1. Crea un disco de 16 GB con `qemu-img create -f raw mi_disco.img 16G`.
2. Instala tu sistema en él, arrancando con la imagen de instalación como `-fda` o `-cdrom`.
3. Copia el resultado a `/var/lib/freedos-kiosk/freedos14full.img`, o cambia la ruta en `freedos-kiosk.sh`.
4. Reinicia el servicio con `sudo systemctl restart freedos-kiosk.service`.

Cualquier sistema que arranque en PC x86 funciona, aunque hay que ajustar `-cpu` y los dispositivos si necesita más memoria o hardware.

### Solución de problemas

- **QEMU no arranca:** `journalctl -u freedos-kiosk -b --no-pager | tail -n 40`.
- **La disquetera no aparece:** `ls -l /dev/floppy-usb`. Desconéctala, espera unos segundos y vuelve a conectarla.
- **Mensajes de Linux en pantalla:** revisa que `/boot/firmware/cmdline.txt` contiene `systemd.show_status=0 fbcon=map:9`.
- **Aviso de JemmEx sobre E400-EBFF:** es un aviso, no un fallo.
- **Sin sonido:** dentro de FreeDOS, ejecuta `SBMIX` para comprobar que el mezclador no está a cero. En la Pi, `wpctl status` debe marcar con `*` la salida que usas.
- **Pitido del altavoz distorsionado:** ajusta el volumen del nodo snd1 en el script.
- **La Pi se limita o se reinicia sola:** revisa la alimentación con `vcgencmd get_throttled`.

### Desinstalar

```bash
sudo systemctl disable --now freedos-kiosk.service
sudo rm /etc/systemd/system/freedos-kiosk.service /usr/local/bin/freedos-kiosk*.sh /usr/local/bin/freedos-kiosk-xinitrc /etc/udev/rules.d/90-floppy-usb.rules
sudo systemctl unmask getty@tty1.service
sudo cp /boot/firmware/cmdline.txt.bak /boot/firmware/cmdline.txt
sudo rm -rf /var/lib/freedos-kiosk
sudo reboot
```

### Limitaciones

- La emulación sin aceleración por hardware es lenta en la Pi. Algunos juegos irán lentos, sobre todo en la Pi 3.
- Ajustes como `thread=multi` o `tb-size` no mejoran el rendimiento de forma medible en la Pi 3 con una sola CPU emulada.
- Los juegos comerciales no se incluyen: cópialos tú a la imagen.
- El altavoz del PC y la tarjeta comparten salida; los volúmenes se ajustan por separado con los nodos de PipeWire.
- La salida HDMI del audio depende del monitor conectado.

---

## English

### Requirements

- Raspberry Pi 3 Model B, 3B+ or 4/400. The 3 is the slowest and has 1 GB of RAM.
- 64-bit Raspberry Pi OS, freshly installed, with Internet access.
- Official power supply, or 5 V and 3 A. A weak supply makes the Pi throttle itself.
- microSD card of 32 GB or more.
- USB floppy drive (tested: NEC USB UF000x).
- About 17 GB free.
- Monitor with HDMI.

### Installation

```bash
git clone https://github.com/USUARIO/freedos-kiosk.git
cd freedos-kiosk
sudo ./instalar.sh
```

The installer sets the user who runs it (`SUDO_USER`) as `RUN_USER` in the script. At the end it asks whether you want to reboot. If not, reboot later with `sudo reboot`.

To force the installer language: `sudo IDIOMA=es ./instalar.sh` or `sudo IDIOMA=en ./instalar.sh`.

### Usage

- **Floppies:** connect the USB floppy drive with a disk inside. It is inserted into A: automatically. When you change disks, FreeDOS reads the new one without rebooting.
- **Mouse:** it is captured when you click in the window. To release it: Ctrl+Alt+G.
- **Full screen:** Ctrl+Alt+F.
- **Shutdown:** type `SHUTDOWN` inside FreeDOS. When QEMU closes, the Pi powers off by default (see "Customize" to change it).

**Important:** never pull the power cable while FreeDOS is running. Always exit with `SHUTDOWN`.

### Project structure

```
freedos-kiosk/
├── instalar.sh                  Installer (bilingual)
├── README.md                    This file
├── src/
│   ├── freedos-kiosk.sh         Launches QEMU, volumes, HDMI output and floppy watcher
│   ├── freedos-kiosk-xinitrc    X session: intro video and launch
│   ├── freedos-kiosk.service    systemd service
│   └── 90-floppy-usb.rules      udev rule: creates /dev/floppy-usb
├── media/
│   └── intro.mp4                Intro video (optional)
└── image/
    ├── freedos14full.img.xz     Compressed FreeDOS image
    └── SHA256SUMS               Image checksum
```

### What gets installed and changed

**Packages:** qemu-system-x86, qemu-system-gui, socat, xinit, openbox, x11-xserver-utils, unclutter, mpv, pulseaudio-utils, xz-utils.

**System files:**

- `/usr/local/bin/freedos-kiosk.sh` and `/usr/local/bin/freedos-kiosk-xinitrc`
- `/etc/systemd/system/freedos-kiosk.service`
- `/etc/udev/rules.d/90-floppy-usb.rules`
- `/var/lib/freedos-kiosk/` (image and video)
- `/boot/firmware/cmdline.txt` (a backup is saved as `cmdline.txt.bak`)
- `/boot/firmware/config.txt`: adds `disable_splash=1` under `[all]`, to hide the rainbow screen at boot.

**System changes:**

- `getty@tty1` is masked (no login on screen).
- The default target becomes `multi-user.target` and `lightdm` is disabled.
- cloud-init and `NetworkManager-wait-online` are disabled to speed up boot. This does not affect networking.
- The welcome wizard (`piwiz.desktop`) is removed.
- `loginctl enable-linger` for your user, so PipeWire is available at boot.

### Customize

- **Volumes:** in `src/freedos-kiosk.sh`, the volume section. The sound card (snd0) and the PC speaker (snd1) are found by name on every boot. Current values: sink 1.00, sound card 1.00, speaker 0.40. Adjust them if your Pi sounds different.
- **Power off on exit:** in `src/freedos-kiosk.sh`, `POWEROFF_AL_SALIR=1` powers the Pi off when QEMU closes. Change it to `0` to keep it on.
- **Memory, CPU, devices:** in the `qemu-system-i386` line of the same script (`-m`, `-cpu`, `-accel`, `-device`).
- **HDMI audio output:** the script automatically looks for the PipeWire HDMI output at boot and uses it as default if it exists. For another output (for example the 3.5 mm jack), change the `pactl set-default-sink` line or use `wpctl set-default` manually.
- **Intro video:** replace `media/intro.mp4` with another before installing, or delete it to skip the intro.

### Overclock (optional, not included in the installer)

The installer does not touch the CPU frequency. To try an overclock, add it by hand to `/boot/firmware/config.txt`, under `[all]`:

```
arm_freq=1300
```

- Suitable values depend on the model and the power supply. The Pi 3 Model B runs at 1.2 GHz from the factory.
- Before raising the frequency, check the power supply: `vcgencmd get_throttled` must return `0x0`. Any other value means under-voltage or thermal throttling.
- If the Pi does not boot after the change, hold Shift during boot to disable the overclock, or remove the lines from the PC by mounting the card.

### Using another system image

The image is called `freedos14full.img` and lives in `/var/lib/freedos-kiosk/`. To use another one:

1. Create a 16 GB disk with `qemu-img create -f raw my_disk.img 16G`.
2. Install your system on it, booting the installation image as `-fda` or `-cdrom`.
3. Copy the result to `/var/lib/freedos-kiosk/freedos14full.img`, or change the path in `freedos-kiosk.sh`.
4. Restart the service with `sudo systemctl restart freedos-kiosk.service`.

Any system that boots on an x86 PC should work, though you may need to adjust `-cpu` and the devices if it needs more memory or hardware.

### Troubleshooting

- **QEMU does not start:** `journalctl -u freedos-kiosk -b --no-pager | tail -n 40`.
- **Floppy drive not detected:** `ls -l /dev/floppy-usb`. Unplug it, wait a few seconds and plug it back in.
- **Linux messages on screen:** check that `/boot/firmware/cmdline.txt` contains `systemd.show_status=0 fbcon=map:9`.
- **JemmEx warning about E400-EBFF:** it is a warning, not an error.
- **No sound:** inside FreeDOS, run `SBMIX` to check the mixer is not at zero. On the Pi, `wpctl status` should show `*` on the output you are using.
- **Distorted PC speaker sound:** adjust the volume of the snd1 node in the script.
- **The Pi throttles or reboots by itself:** check the power supply with `vcgencmd get_throttled`.

### Uninstall

```bash
sudo systemctl disable --now freedos-kiosk.service
sudo rm /etc/systemd/system/freedos-kiosk.service /usr/local/bin/freedos-kiosk*.sh /usr/local/bin/freedos-kiosk-xinitrc /etc/udev/rules.d/90-floppy-usb.rules
sudo systemctl unmask getty@tty1.service
sudo cp /boot/firmware/cmdline.txt.bak /boot/firmware/cmdline.txt
sudo rm -rf /var/lib/freedos-kiosk
sudo reboot
```

### Limitations

- Emulation without hardware acceleration is slow on the Pi. Some games will run slowly, especially on the Pi 3.
- Settings such as `thread=multi` or `tb-size` have no measurable effect on a Pi 3 with a single emulated CPU.
- Commercial games are not included: copy them into the image yourself.
- The PC speaker and the sound card share the output; volumes are adjusted separately with PipeWire nodes.
- The HDMI audio output depends on the connected monitor.

---

## Licencia / License

Los scripts pueden distribuirse bajo la licencia que elijas (por ejemplo, MIT). FreeDOS, JemmEx, mTCP y los drivers incluidos tienen sus propias licencias libres. / The scripts can be distributed under the license you choose (for example MIT). FreeDOS, JemmEx, mTCP and the included drivers have their own free licenses.
