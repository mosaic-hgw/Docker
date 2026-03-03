#!/bin/bash

# get commons
source ${HOME}/commons.sh

TRUSTSTORE="${ENTRY_JAVA_CACERTS}"
TRUSTS_DIR="${ENTRY_JAVA_TRUSTS}"
JAVA_CACERTS_PASS="${JAVA_CACERTS_PASS:-changeit}"

if [ ! -d "${TRUSTS_DIR}" ]; then
  echoErr "Source directory '${TRUSTS_DIR}' does not exist."
  exit 2
fi

# helper: check alias existence
alias_exists() {
  keytool -list -keystore "${TRUSTSTORE}" -storepass "${JAVA_CACERTS_PASS}" -alias "${1}" >/dev/null 2>&1
}

# helper: import cert
import_cert() {
  local file="${1}"
  local alias="${2}"
  echoInfo "Importing certificate '${file}' (alias='${alias}')"
  keytool -importcert -trustcacerts -noprompt -file "${file}" -alias "${alias}" -cacerts -storepass "${JAVA_CACERTS_PASS}"
}

# collect certificates
shopt -s nullglob
CERTS=( "${TRUSTS_DIR}"/*.crt "${TRUSTS_DIR}"/*.cer "${TRUSTS_DIR}"/*.pem )

if [ "${#CERTS[@]}" -eq 0 ]; then
  echoInfo "No certificate files found in '${TRUSTS_DIR}'. Nothing to do."
  exit
fi

# process certificates
for CERT in "${CERTS[@]}"; do
  [ -f "${CERT}" ] || continue

  FILENAME="$(basename -- "${CERT}")"
  CERT_ALIAS="${FILENAME%.*}"

  if alias_exists "${CERT_ALIAS}"; then
    echoInfo "Alias '${CERT_ALIAS}' already exists — replacing it."
    keytool -delete -alias "${CERT_ALIAS}" -cacerts -storepass "${JAVA_CACERTS_PASS}" || {
      echoErr "Failed to delete alias '${CERT_ALIAS}'. Skipping."
      continue
    }
  fi

  if ! import_cert "${CERT}" "${CERT_ALIAS}"; then
    echoErr "Failed to import '${CERT}'."
  fi
done

echoInfo "Certificate import completed (summary $(keytool -list -cacerts 2>/dev/null | grep fingerprint | wc -l) certs)."
echo "${LINE}"
