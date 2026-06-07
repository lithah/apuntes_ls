#!/usr/bin/env bash
set -euo pipefail

confirm() {
  printf "%s [y/N]: " "$1"
  read -r ans
  case "$ans" in
    [Yy]|[Yy][Ee][Ss]) return 0 ;;
    *) return 1 ;;
  esac
}

echo "Resumen de espacio antes:"
df -h /
echo
sudo du -xh --max-depth=1 / | sort -hr | sed -n '1,10p'
echo

if confirm "1) Ejecutar 'sudo apt clean' y 'sudo apt autoremove --purge -y' ?"; then
  sudo apt clean
  sudo apt autoremove --purge -y
fi

if confirm "2) Vaciar caché de root (/root/.cache) ?"; then
  sudo rm -rf /root/.cache/* || true
fi

if confirm "3) Vaciar cachés .cache en /home (para todos los usuarios) ? (Elimina miniaturas y caches de aplicaciones)"; then
  sudo find /home -maxdepth 2 -type d -name ".cache" -exec rm -rf {}/* \; 2>/dev/null || true
fi

if confirm "4) Limpiar /var/cache/apt/archives (*.deb) ?"; then
  sudo rm -rf /var/cache/apt/archives/*.deb || true
fi

echo
echo "Tamaño de /var/log (primer vistazo):"
sudo du -sh /var/log/* 2>/dev/null | sort -h | sed -n '1,20p'
echo

if confirm "5) Truncar logs comunes (/var/log/syslog, /var/log/kern.log, /var/log/auth.log) ?"; then
  sudo truncate -s 0 /var/log/syslog /var/log/kern.log /var/log/auth.log 2>/dev/null || true
fi

if confirm "6) Forzar rotación de logs con logrotate?"; then
  sudo logrotate --force /etc/logrotate.conf || true
fi

if confirm "7) Reducir journalctl (systemd) a 200 MB?"; then
  sudo journalctl --vacuum-size=200M || true
fi

if confirm "8) Vaciar thumbnails en /var/cache/thumbnails ?"; then
  sudo rm -rf /var/cache/thumbnails/* 2>/dev/null || true
fi

echo
echo "Comprobando archivos borrados aún retenidos por procesos (lsof +L1):"
sudo lsof +L1 2>/dev/null || true

echo
if confirm "¿Reiniciar servicios/processos listados arriba o reiniciar el sistema ahora? (respóndele manualmente; si no, salta)"; then
  echo "Reiniciando sistema..."
  sudo reboot
else
  echo "Hecho. Revisa 'sudo lsof +L1' y reinicia manualmente los servicios o el sistema si es necesario."
fi
