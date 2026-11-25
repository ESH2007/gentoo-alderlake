# Controlar el servidor CachyOS desde el portátil

El portátil es el **cliente**; el PC de compilación con **CachyOS** es el
**servidor**. Se conectan por **Tailscale** (funciona desde cualquier red, sin
abrir puertos en el router) y hay tres formas de usarlo:

| Forma | Programa en el portátil | Programa en CachyOS | Para qué |
|-------|-------------------------|---------------------|----------|
| Terminal | `ssh` + `tmux` (y `mosh` en redes malas) | `sshd` | compilar, administrar; gasta casi nada |
| Ver la pantalla | **Remmina** (RDP) | **KRdp** (KDE) o Escritorio remoto de GNOME | usar el escritorio del servidor |
| Pantalla muy fluida (opcional) | **Moonlight** | **Sunshine** | vídeo, juegos, 60 fps |
| Archivos | `sshfs` (`~/servidor`) | `sshd` | abrir archivos del servidor como si fueran locales |

Todo se abre desde el menú: **SUPER+CTRL+S** (o *Menú ESH → Servidor*).

---

## Parte A — Portátil (Gentoo), hacerlo antes del viaje

Requisito: Tailscale ya instalado y con sesión iniciada (`tailscale status`
muestra el portátil). El kernel ya trae TUN; para **sshfs** hace falta FUSE,
que entra la próxima vez que recompiles el kernel con `kernel/build.sh`.

**1. Actualizar el repo e instalar los programas**

```sh
cd /opt/gentoo-alderlake && sudo git pull
sudo cp portage/package.use/* /etc/portage/package.use/
sudo cp portage/package.accept_keywords/* /etc/portage/package.accept_keywords/
sudo emerge -av app-misc/esh-desktop
./dotfiles/install.sh
```

Esto instala `openssh`, `mosh`, `tmux`, `sshfs` y `remmina`. Remmina se compila
en local (unos minutos); FreeRDP llega ya compilado del binhost.

**2. Crear tu llave SSH** (una sola vez; pulsa Enter a todo o ponle frase)

```sh
ssh-keygen -t ed25519 -C "elsancho@portatil"
```

**3. Crear el alias `build`** (así no tienes que recordar la IP)

```sh
mkdir -p ~/.ssh && cat >> ~/.ssh/config <<'EOF'
Host build
    HostName cachy
    User elsancho
    ServerAliveInterval 30
    ServerAliveCountMax 4
EOF
chmod 600 ~/.ssh/config
```

`cachy` es el nombre que tendrá el servidor en Tailscale (lo pones en la parte B).
Si usas otro nombre o usuario, cambia esas dos líneas.

**Moonlight (opcional).** Solo si vas a usar Sunshine en el servidor:

```sh
echo 'app-misc/esh-desktop stream' | sudo tee /etc/portage/package.use/esh-stream
sudo emerge -av --autounmask=y app-misc/esh-desktop
```

Trae Qt 6 (casi todo del binhost). Si `emerge` pide cambios de USE, acéptalos
con `sudo dispatch-conf` y repite.

---

## Parte B — Servidor (CachyOS), al montar el PC en Chicago

Durante la instalación de CachyOS elige **KDE Plasma** (es el escritorio por
defecto) y crea el usuario **`elsancho`**. Luego, en una terminal del servidor:

**1. Nombre y Tailscale**

```sh
sudo hostnamectl set-hostname cachy
sudo pacman -S --needed tailscale
sudo systemctl enable --now tailscaled
sudo tailscale up
```

Abre el enlace que sale e inicia sesión con **la misma cuenta** que en el portátil.

**2. SSH**

```sh
sudo pacman -S --needed openssh tmux mosh
sudo systemctl enable --now sshd
```

Ahora, **desde el portátil**, copia tu llave y prueba:

```sh
ssh-copy-id build
ssh build
```

Cuando `ssh build` entre sin pedir contraseña, desactiva las contraseñas en el
servidor (más seguro):

```sh
echo -e 'PasswordAuthentication no\nKbdInteractiveAuthentication no' | sudo tee /etc/ssh/sshd_config.d/10-solo-llaves.conf
sudo systemctl restart sshd
```

**3. Escritorio remoto (RDP con KRdp)**

```sh
sudo pacman -S --needed krdp
```

Después: *Preferencias del sistema → Escritorio remoto* (Remote Desktop) →
actívalo, añade un usuario y contraseña **solo para RDP** y marca que se inicie
con la sesión.

KRdp comparte la sesión que está abierta, así que para que funcione sin nadie
delante del servidor:

- *Preferencias → Colores y temas → Pantalla de inicio de sesión (SDDM) →
  Comportamiento*: **inicio de sesión automático** como `elsancho`.
- *Preferencias → Gestión de energía*: que **no suspenda** ni apague la pantalla
  con corriente, y en *Bloqueo de pantalla* desactiva el bloqueo automático.

> Si elegiste GNOME en vez de KDE: *Configuración → Sistema → Escritorio remoto*
> trae RDP integrado (incluye "Inicio de sesión remoto", que no necesita sesión
> abierta). En el portátil se usa igual, con Remmina.

**4. Cortafuegos.** Si `sudo ufw status` dice `active`, deja pasar todo lo que
llegue por Tailscale (y nada más):

```sh
sudo ufw allow in on tailscale0
```

**5. Sunshine (opcional, para Moonlight)**

```sh
sudo pacman -S --needed sunshine || paru -S sunshine
sudo setcap cap_sys_admin+p "$(readlink -f "$(command -v sunshine)")"
systemctl --user enable --now sunshine
```

Abre `https://localhost:47990` en el servidor, crea usuario y contraseña. Al
añadir el servidor en Moonlight (portátil) saldrá un PIN: escríbelo en la web
de Sunshine (*PIN*).

---

## Uso diario (portátil)

| Quiero… | Cómo |
|---------|------|
| Terminal en el servidor | **SUPER+CTRL+S → Terminal**, o `ssh build`. Entra en `tmux` sesión `main`: si se corta la red, vuelve a entrar y sigues donde estabas (`CTRL+B` y luego `D` para salir dejándolo corriendo) |
| Terminal en Wi‑Fi malo (hotel, móvil) | `mosh build -- tmux new -A -s main` |
| Ver la pantalla | **SUPER+CTRL+S → Escritorio remoto**. En Remmina: **+** → Protocolo **RDP**, Servidor `cachy`, usuario/contraseña de KRdp → Guardar y conectar. Calidad: *Mejor (ajustar automáticamente)* |
| Pantalla fluida | **SUPER+CTRL+S → Streaming** (Moonlight) → elige `cachy` → *Desktop* |
| Archivos del servidor | **SUPER+CTRL+S → Montar carpetas**: aparecen en `~/servidor` (otra vez para desmontar) |
| ¿Está encendido? | **SUPER+CTRL+S → Estado de Tailscale**, o `tailscale ping cachy` |

## Si algo falla

- `ssh: Could not resolve hostname cachy`: activa **MagicDNS** en el panel de
  Tailscale (*DNS → Enable MagicDNS*) o usa la IP `100.x.y.z` que sale en
  `tailscale status`.
- Remmina conecta pero la pantalla sale negra: la sesión del servidor está
  bloqueada o no hay sesión abierta (revisa el inicio automático del paso B3).
- Moonlight no ve el servidor: añádelo a mano con **+** y el nombre `cachy`.
