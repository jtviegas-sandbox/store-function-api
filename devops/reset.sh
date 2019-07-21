#!/bin/sh

this_folder="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
parent_folder=$(dirname $this_folder)

. ${this_folder}/lib
. ${this_folder}/include
if [[ -z $TENANT ]] ; then err "no TENANT defined" && exit 1; fi

. ${this_folder}/"${TENANT}.include"

STORE_FUNCTION_ROLE="${TENANT}_store_function_role"
STORE_FUNCTION_ROLE_POLICY="${TENANT}_store_function_role_policy"
LOGGING_POLICY="${TENANT}_logging_policy"
FUNCTION_BUCKET="${TENANT}.${FUNCTION_BUCKET_SUFFIX}"
SRC_DIR=${parent_folder}/src
API_STACK="${TENANT}-${PROJ}"


__r=0

debug "resetting api..."

rm ${parent_folder}/${API_URL_FILE}
deleteStack ${API_STACK}
rm ${SRC_DIR}/packaged.yaml
deleteBucket ${FUNCTION_BUCKET}
rm -r ${parent_folder}/src/.aws-sam
rm ${parent_folder}/src/template.yaml
detachRoleFromPolicy ${STORE_FUNCTION_ROLE} ${LOGGING_POLICY}
deletePolicy ${LOGGING_POLICY}
detachRoleFromPolicy ${STORE_FUNCTION_ROLE} ${STORE_FUNCTION_ROLE_POLICY}
deletePolicy ${STORE_FUNCTION_ROLE_POLICY}
deleteRole ${STORE_FUNCTION_ROLE}

debug "...api reset done."
