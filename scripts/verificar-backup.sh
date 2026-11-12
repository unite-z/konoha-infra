#!/usr/bin/env bash
# Comprueba que un respaldo (directorio con db.dump, adjuntos.tar.gz, SHA256SUMS y manifiesto.env) está
# completo y íntegro. Sale con código 1 y un mensaje claro ante cualquier fallo.
# Uso: verificar-backup.sh <directorio> [<uat|prod>]
# shellcheck source=comun.sh
source "$(dirname "$0")/comun.sh"

dir="${1:?Falta el directorio del respaldo}"
esperado="${2:-}"

for f in manifiesto.env SHA256SUMS db.dump adjuntos.tar.gz; do
  [[ -s "$dir/$f" ]] || error "Respaldo incompleto: falta $f (o está vacío) en $dir."
done
manifiesto() { grep -E "^$1=" "$dir/manifiesto.env" | tail -n 1 | cut -d= -f2-; }
[[ "$(manifiesto estado)" == "completo" ]] || error "El manifiesto no marca el respaldo como completo."
[[ -z "$esperado" || "$(manifiesto entorno)" == "$esperado" ]] \
  || error "El respaldo es de '$(manifiesto entorno)', no de '$esperado': no se mezclan entornos."
(cd "$dir" && "${SHA256[@]}" -c --quiet SHA256SUMS) || error "Checksum incorrecto: el respaldo está corrupto."
n="$(tar -tzf "$dir/adjuntos.tar.gz" | grep -vc '/$' || true)"
[[ "$n" == "$(manifiesto adjuntos_ficheros)" ]] \
  || error "Faltan adjuntos: el tar tiene $n ficheros y el manifiesto declara $(manifiesto adjuntos_ficheros)."
log "Respaldo íntegro: $(manifiesto entorno) $(manifiesto fecha), $n adjuntos, checksums correctos."
