#!/usr/bin/env bash
# Pasa a Done en Linear los tickets que acaban de llegar a producción.
# Saca los AV-n de los commits nuevos de backend y frontend (de la versión que había en prod a la nueva)
# y mueve los que están en «In Testing» o «In Review». Nunca hace fallar la promoción: solo avisa.
# Variables: LINEAR_API_KEY, GH_TOKEN, API_PREVIO, WEB_PREVIO, API_NUEVO, WEB_NUEVO.
# Con SECO=1 lista lo que movería sin tocar Linear.
set -uo pipefail

ESTADOS_ORIGEN='["In Testing", "In Review"]'
resumen() { echo "$*" >> "${GITHUB_STEP_SUMMARY:-/dev/stdout}"; }
avisa() { echo "::warning::$*"; resumen "⚠️ $*"; exit 0; }

# Consulta GraphQL a Linear: $1 es la consulta y $2, las variables en JSON (por defecto, ninguna).
linear() {
  local variables="${2:-}"
  [[ -n "$variables" ]] || variables='{}'
  curl -sS --max-time 20 https://api.linear.app/graphql \
    -H "Authorization: $LINEAR_API_KEY" -H "Content-Type: application/json" \
    -d "$(jq -n --arg q "$1" --argjson v "$variables" '{query: $q, variables: $v}')"
}

# Mensajes de los commits entre la versión anterior y la nueva de un repo (vacío si no hay anterior).
commits() {
  local repo="$1" previo="$2" nuevo="$3"
  [[ -z "$previo" || "$previo" == "$nuevo" ]] && return 0
  gh api "repos/unite-z/$repo/compare/$previo...$nuevo" --jq '.commits[].commit.message'
}

resumen "### Linear: tickets en producción"
if [[ -z "${API_PREVIO:-}" && -z "${WEB_PREVIO:-}" ]]; then
  avisa "No había versión anterior en prod: no se sabe qué tickets son nuevos. Muévelos a Done a mano."
fi

tickets="$( { commits konoha-backend "${API_PREVIO:-}" "$API_NUEVO"; commits konoha-frontend "${WEB_PREVIO:-}" "$WEB_NUEVO"; } \
  | grep -oE '\bAV-[0-9]+\b' | sort -u -t- -k2,2n || true)"
if [[ -z "$tickets" ]]; then
  resumen "Ningún ticket nuevo en esta promoción."
  exit 0
fi
echo "Tickets en la promoción: $(tr '\n' ' ' <<< "$tickets")"

if [[ "${SECO:-}" == "1" ]]; then
  resumen "(SECO) Se pasarían a Done, si están en In Testing o In Review: $(tr '\n' ' ' <<< "$tickets")"
  exit 0
fi
[[ -n "${LINEAR_API_KEY:-}" ]] || avisa "Falta el secret LINEAR_API_KEY: no se ha movido ningún ticket."

quien="$(linear 'query { viewer { name } }' | jq -r '.data.viewer.name // empty')"
[[ -n "$quien" ]] || avisa "LINEAR_API_KEY no es válida o Linear no responde: no se ha movido ningún ticket."

movidos=() ; omitidos=()
# Los $ de las consultas son variables de GraphQL, no de bash: van entre comillas simples a propósito.
# shellcheck disable=SC2016
for t in $tickets; do
  datos="$(linear 'query($id: String!) { issue(id: $id) { id identifier state { name } team { states { nodes { id name type } } } } }' \
    "$(jq -n --arg id "$t" '{id: $id}')")"
  estado="$(jq -r '.data.issue.state.name // empty' <<< "$datos")"
  if [[ -z "$estado" ]]; then omitidos+=("$t (no existe)"); continue; fi
  if ! jq -e --arg e "$estado" --argjson o "$ESTADOS_ORIGEN" '$o | index($e)' >/dev/null <<< 'null'; then
    omitidos+=("$t ($estado)"); continue
  fi
  done_id="$(jq -r '[.data.issue.team.states.nodes[] | select(.type == "completed")][0].id' <<< "$datos")"
  issue_id="$(jq -r '.data.issue.id' <<< "$datos")"
  ok="$(linear 'mutation($id: String!, $s: String!) { issueUpdate(id: $id, input: { stateId: $s }) { success } }' \
    "$(jq -n --arg id "$issue_id" --arg s "$done_id" '{id: $id, s: $s}')" | jq -r '.data.issueUpdate.success // false')"
  if [[ "$ok" == "true" ]]; then movidos+=("$t"); else omitidos+=("$t (error al mover)"); fi
done

resumen "- Pasan a Done: ${movidos[*]:-ninguno}"
resumen "- Sin cambios: ${omitidos[*]:-ninguno}"
exit 0
