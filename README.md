## Español

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

## Requisitos: ¿Qué necesitas?

Antes de empezar, asegúrate de tener a mano lo siguiente. Aquí no hay máquinas virtuales mágicas ni disqueteras imaginarias: necesitamos hardware real.

Raspberry Pi: modelos 3 Model B, 3B+, 4 o 400.

La Raspberry Pi 3 Model B es la menos recomendable. Su procesador es el más lento de los modelos compatibles y sus 1 GB de RAM la convierten en la opción más limitada. Si buscas una experiencia lo más cercana posible a la original, es preferible utilizar una Pi 4.

Sistema operativo: Raspberry Pi OS de 64 bits, recién instalado y con conexión a Internet.

Almacenamiento: tarjeta microSD de 32 GB.

Disquetera: unidad USB compatible (probada con NEC USB UF000x y TEAC FD-05PUB).

Disquetes: por supuesto, necesitarás disquetes físicos. No hemos llegado hasta aquí para utilizar imágenes virtuales.


## Instalación: manos a la obra

Clona el repositorio y ejecuta el instalador. Él se encargará de preparar el sistema y configurar los componentes necesarios.

git clone https://github.com/USUARIO/freedos-kiosk.git
cd freedos-kiosk
sudo ./instalar.sh

El instalador utiliza automáticamente el usuario que lo ejecuta (SUDO_USER) como usuario de ejecución (RUN_USER).

Al finalizar, te preguntará si deseas reiniciar el sistema. Si prefieres hacerlo más tarde, puedes reiniciar manualmente:

sudo reboot

# ¿Necesitas cambiar el idioma del instalador?

Puedes forzarlo mediante la variable IDIOMA:

sudo IDIOMA=es ./instalar.sh

O utilizar inglés:

sudo IDIOMA=en ./instalar.sh

# Uso: bienvenido de nuevo a los años 80

Una vez instalado y reiniciado el sistema, Flop-Py arrancará automáticamente.

Estas son algunas de las operaciones básicas:

Disquetes: conecta la disquetera USB con un disco insertado. Flop-Py lo reconocerá automáticamente como unidad A:. Cuando cambies de disco, el sistema detectará el nuevo sin necesidad de reiniciar.

Ratón: queda capturado al hacer clic dentro de la ventana. 

Pantalla completa: Automatica.

Apagado: escribe SHUTDOWN dentro de FreeDOS. Al cerrarse QEMU, la Raspberry Pi se apagará automáticamente por defecto. 

IMPORTANTE: no desconectes la alimentación de la Raspberry Pi mientras FreeDOS esté funcionando. Utiliza siempre el comando SHUTDOWN para apagar correctamente el sistema.

## Estructura del proyecto

Esta es la organización de los archivos del repositorio:

freedos-kiosk/
├── instalar.sh                  Instalador (bilingüe)
├── README.md                    Documentación del proyecto
├── src/
│   ├── freedos-kiosk.sh         Lanzamiento de QEMU, volúmenes,
│   │                            salida HDMI y vigilancia de disquetes
│   ├── freedos-kiosk-xinitrc    Sesión X: vídeo de introducción
│   │                            y lanzamiento del sistema
│   ├── freedos-kiosk.service    Servicio de systemd
│   └── 90-floppy-usb.rules      Regla udev para /dev/floppy-usb
├── media/
│   └── intro.mp4                Vídeo de introducción (opcional)
└── image/
    ├── freedos14full.img.xz     Imagen comprimida de FreeDOS
    └── SHA256SUMS               Suma de verificación de la imagen

# ¿Qué instala y qué modifica?

Flop-Py necesita preparar algunos componentes del sistema operativo para ofrecer una experiencia de arranque directa, sin escritorios ni elementos innecesarios.

# Paquetes instalados

qemu-system-x86

qemu-system-gui

socat

xinit

openbox

x11-xserver-utils

unclutter

mpv

pulseaudio-utils

xz-utils

# Archivos del sistema

El instalador crea o modifica los siguientes archivos y directorios:

/usr/local/bin/freedos-kiosk.sh

/usr/local/bin/freedos-kiosk-xinitrc

/etc/systemd/system/freedos-kiosk.service

/etc/udev/rules.d/90-floppy-usb.rules

/var/lib/freedos-kiosk/ (imagen del sistema y vídeo)

/boot/firmware/cmdline.txt (se conserva una copia de seguridad en cmdline.txt.bak)

/boot/firmware/config.txt (añade disable_splash=1 dentro de [all] para eliminar la pantalla del arcoíris durante el arranque).

# Modificaciones del sistema

Para conseguir un arranque directo, el instalador realiza los siguientes cambios:

Enmascara getty@tty1, eliminando el inicio de sesión en la terminal principal.

Cambia el destino de arranque predeterminado a multi-user.target y desactiva lightdm.

Desactiva cloud-init y NetworkManager-wait-online para acelerar el arranque, sin desactivar la conectividad de red.

Elimina el asistente de bienvenida (piwiz.desktop).

Activa loginctl enable-linger para el usuario de ejecución, permitiendo que PipeWire esté disponible durante el arranque.

# Personalización: cada máquina es un mundo

Aunque Flop-Py viene preparado para funcionar directamente, puedes modificar algunos parámetros para adaptar la experiencia a tu hardware.

# Memoria, CPU y dispositivos

En el mismo archivo encontrarás la línea de ejecución de qemu-system-i386.

Allí puedes modificar los parámetros de memoria (-m), procesador (-cpu), aceleración (-accel) y dispositivos (-device).

Salida de audio HDMI

El script busca automáticamente la salida HDMI de PipeWire durante el arranque y la establece como predeterminada cuando está disponible.

Si prefieres utilizar otra salida, como el conector jack de 3,5 mm, puedes modificar la línea pactl set-default-sink o establecer manualmente la salida mediante:

wpctl set-default

# Vídeo de introducción

Puedes sustituir media/intro.mp4 por otro vídeo antes de instalar el sistema.

Si prefieres arrancar directamente sin introducción, simplemente elimina ese archivo.

# Apagado automático

Por defecto, la Raspberry Pi se apaga al cerrar QEMU.

En src/freedos-kiosk.sh, localiza:

POWEROFF_AL_SALIR=1

Cambia el valor a 0 si prefieres que la Raspberry Pi permanezca encendida después de salir de QEMU.

# Overclock (opcional)

El instalador no modifica las frecuencias de funcionamiento de la CPU.

Si quieres experimentar con un pequeño overclock, puedes añadir manualmente la siguiente configuración en /boot/firmware/config.txt, dentro de la sección [all]:

arm_freq=1300

Tenga en cuenta lo siguiente:

Los valores admitidos dependen del modelo de Raspberry Pi y de la alimentación utilizada.

La Raspberry Pi 3 Model B funciona de fábrica a 1,2 GHz.

Antes de experimentar con frecuencias superiores, comprueba que la alimentación es estable antes de ejecutar el instalador:

vcgencmd get_throttled

El resultado esperado es 0x0. Cualquier otro valor puede indicar problemas de alimentación, limitación térmica u otros eventos de throttling.

Si la Raspberry Pi deja de arrancar después de modificar las frecuencias, puedes retirar la configuración desde otro ordenador, conectando la tarjeta microSD y editando config.txt.

# Utilizar otra imagen de sistema

La imagen de FreeDOS utilizada por Flop-Py se encuentra en:

/var/lib/freedos-kiosk/freedos14full.img

Si quieres experimentar con otro sistema operativo compatible con x86, puedes sustituirla por tu propia imagen.

Procedimiento:

Crea un disco virtual de 16 GB:

qemu-img create -f raw mi_disco.img 16G

Instala el sistema operativo que quieras utilizando la imagen de instalación correspondiente, arrancando desde ella mediante -fda o -cdrom.

Copia el resultado a /var/lib/freedos-kiosk/freedos14full.img o modifica la ruta de la imagen en freedos-kiosk.sh.

Reinicia el servicio:

sudo systemctl restart freedos-kiosk.service

En principio, cualquier sistema operativo compatible con PC x86 que pueda arrancar mediante QEMU debería funcionar. No obstante, puede ser necesario modificar los parámetros de CPU, memoria y dispositivos virtuales.

## Solución de problemas

Porque, seamos sinceros, estamos recreando una época en la que las cosas no siempre funcionaban a la primera.

Estos son algunos de los problemas más habituales y cómo diagnosticarlos.

Problema

Solución

QEMU no arranca

Consulta los registros con journalctl -u freedos-kiosk -b --no-pager | tail -n 40.

La disquetera no aparece

Comprueba /dev/floppy-usb con ls -l /dev/floppy-usb. Desconecta la unidad, espera unos segundos y vuelve a conectarla.

Aparecen mensajes de Linux en pantalla

Comprueba que /boot/firmware/cmdline.txt contiene systemd.show_status=0 fbcon=map:9.

Aviso de JemmEx sobre E400-EBFF

Es un aviso conocido, no un error de funcionamiento.

No hay sonido

Ejecuta SBMIX dentro de FreeDOS para comprobar que el mezclador no está silenciado. En Raspberry Pi, utiliza wpctl status para comprobar la salida activa.

El altavoz interno suena distorsionado

Reduce el volumen del nodo snd1 en el script.

La Raspberry Pi reduce su rendimiento o se reinicia

Comprueba la alimentación y la temperatura mediante vcgencmd get_throttled.

## Desinstalación

Si decides retirar Flop-Py de tu Raspberry Pi, puedes ejecutar los siguientes comandos:

sudo systemctl disable --now freedos-kiosk.service
sudo rm /etc/systemd/system/freedos-kiosk.service /usr/local/bin/freedos-kiosk*.sh /usr/local/bin/freedos-kiosk-xinitrc /etc/udev/rules.d/90-floppy-usb.rules
sudo systemctl unmask getty@tty1.service
sudo cp /boot/firmware/cmdline.txt.bak /boot/firmware/cmdline.txt
sudo rm -rf /var/lib/freedos-kiosk
sudo reboot

Tenga en cuenta que este procedimiento elimina los archivos de Flop-Py y restaura cmdline.txt, pero no revierte automáticamente todos los cambios realizados durante la instalación.

## Limitaciones conocidas

No vamos a venderte humo. La Raspberry Pi tiene sus limitaciones y la emulación de hardware x86 tiene un coste de rendimiento.

Rendimiento: la emulación sin aceleración por hardware puede resultar lenta, especialmente en Raspberry Pi 3. Algunos juegos y aplicaciones exigirán más recursos de los disponibles.

Procesamiento: parámetros como thread=multi o tb-size no proporcionan mejoras de rendimiento medibles en Raspberry Pi 3 con una única CPU emulada.

Software comercial: los juegos y programas comerciales no se incluyen. Tendrás que incorporarlos tú mismo a la imagen.

Audio: el altavoz interno del PC y la tarjeta de sonido comparten la salida de audio, aunque sus volúmenes se pueden ajustar independientemente mediante PipeWire.

HDMI: la disponibilidad de la salida de audio HDMI depende del monitor o televisor conectado.

Recuerda: Flop-Py no pretende convertir una Raspberry Pi en un PC moderno. Pretende acercarte a la experiencia de utilizar uno de aquellos ordenadores, con sus limitaciones y peculiaridades.

Y eso incluye aceptar que, algunas veces, tendrás que esperar.

---

## English

## Flop-Py: What Is It and What Is Its Philosophy?

Flop-Py was born out of nostalgia for bringing back the authentic experience of the early x86 computers: the clatter of floppy disk drives, the storage limitations, and the unmistakable sound of Sound Blaster cards.

But Flop-Py doesn't just want to imitate that era. It wants you to experience it all over again.

The project is designed to work with physical floppy disks through a USB drive (get ready, because you'll need actual floppy disks), preserving both their advantages and their drawbacks. No shortcuts that take away from the original experience. All this while taking advantage of the connectivity and compact size of devices like the Raspberry Pi, because let's face it, space is at a premium.

**You won't find any unnecessary conveniences here.**

If you're looking for a modern emulator that lets you use virtual drives, mount ISO images, or enjoy all the conveniences we've grown accustomed to nowadays, this probably isn't the place for you.

Flop-Py follows a different philosophy: bringing back the experience of sitting in front of a computer from the mid-1980s. That means wrestling with CONFIG.SYS and AUTOEXEC.BAT again, tweaking conventional memory, dealing with hardware limitations and, of course, patiently waiting for the floppy drive to finish doing its job.

Because here, loading times aren't simulated: they're endured and enjoyed.

Flop-Py isn't for everyone. It's a project for those who grew up with that kind of computing, for curious minds who want to discover how things really worked back then, and for those who believe that configuring a computer was almost as much fun as actually using it.

**If you've ever booted a computer from a 3½-inch floppy disk, you probably know exactly what we're talking about.**

**Computing the way it used to be. With the limitations it used to have. And without apologizing for any of it.**

**Welcome to Flop-Py.**

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
