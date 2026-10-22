#!/usr/bin/env bash
# Vuelve a la versión anterior de un entorno (la de version.env.anterior).
# Solo cambia imágenes: las migraciones no se deshacen, por eso tienen que ser expand/contract.
# Uso: volver-atras.sh <uat|prod>
# shellcheck source=comun.sh
source "$(dirname "$0")/comun.sh"

entorno="${1:-}"
validar_entorno "$entorno"
dir="$KONOHA_DIR/$entorno"
[[ -f "$dir/version.env.anterior" ]] || error "No hay versión anterior registrada en $dir."

cp "$dir/version.env" "$dir/version.env.fallida"
cp "$dir/version.env.anterior" "$dir/version.env"
log "Volviendo a: $(tr '\n' ' ' < "$dir/version.env")"
compose "$entorno" up -d --remove-orphans --wait --wait-timeout 300
"$(dirname "$0")/smoke-test.sh" "$entorno"
log "Vuelta atrás en $entorno correcta."
