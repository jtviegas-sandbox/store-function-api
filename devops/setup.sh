#!/bin/sh

this_folder="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
parent_folder=$(dirname $this_folder)

curl -XGET https://raw.githubusercontent.com/jtviegas/script-utils/master/bash/aws.sh -o "${this_folder}"/aws.sh

. ${this_folder}/aws.sh
. ${this_folder}/include

if [[ -z $TENANT ]] ; then err "no TENANT defined" && exit 1; fi

. ${this_folder}/"${TENANT}.include"

DEFAULT_ROLE_POLICY_FILE=${this_folder}/$DEFAULT_ROLE_POLICY
STORE_FUNCTION_ROLE="${TENANT}_store_function_role"
STORE_FUNCTION_ROLE_POLICY="${TENANT}_store_function_role_policy"
LOGGING_POLICY="${TENANT}_logging_policy"
FUNCTION_BUCKET="${TENANT}.${FUNCTION_BUCKET_SUFFIX}"
SRC_DIR=${parent_folder}/src
API_STACK="${TENANT}-${PROJ}"

_pwd=`pwd`
cd ${this_folder}

__r=0

debug "building $PROJ..."

debug "...creating role: ${STORE_FUNCTION_ROLE}..."
createRole ${STORE_FUNCTION_ROLE} ${DEFAULT_ROLE_POLICY_FILE}
__r=$?
if [[ ! "$__r" -eq "0" ]] ; then exit 1; fi


debug "...creating additional policies..."

#tables_arn=
#for _table in $TABLES; do
#    arn=`aws dynamodb describe-table --output text --table-name $_table | grep arn.*$_table | awk '{print $4}'`
#    arn=`echo $arn  | sed "s/\//\\//g"`
#    if [ -z $tables_arn ]; then
#        tables_arn="$arn"
#    else
#        tables_arn="$tables_arn,$arn"
#    fi
#done

tables_arn="arn:aws:dynamodb:${REGION}:*:table/${TENANT}_*"

debug "...building policy $STORE_FUNCTION_ROLE_POLICY..."
debug "...adding dyndb read actions to policy $STORE_FUNCTION_ROLE_POLICY..."
policy=$(buildPolicy "Allow" "$DYNDB_READ_ACTIONS" "$tables_arn")
sleep 1
debug "...creating policy: $STORE_FUNCTION_ROLE_POLICY..."
createPolicy ${STORE_FUNCTION_ROLE_POLICY} "$policy"
__r=$?
if [[ ! "$__r" -eq "0" ]] ; then exit 1; fi

policy=$(buildPolicy "Allow" "$LOGGING_ACTIONS" "arn:aws:logs:*:*:*")
debug "...creating policy: $LOGGING_POLICY..."
createPolicy ${LOGGING_POLICY} "$policy"
__r=$?
if [[ ! "$__r" -eq "0" ]] ; then exit 1; fi

debug "...attaching $STORE_FUNCTION_ROLE role to policy $STORE_FUNCTION_ROLE_POLICY ..."
attachRoleToPolicy ${STORE_FUNCTION_ROLE} ${STORE_FUNCTION_ROLE_POLICY}
__r=$?
if [[ ! "$__r" -eq "0" ]] ; then exit 1; fi
    

debug "...attaching $STORE_FUNCTION_ROLE role to policy $LOGGING_POLICY ..."
attachRoleToPolicy ${STORE_FUNCTION_ROLE} ${LOGGING_POLICY}
__r=$?
if [[ ! "$__r" -eq "0" ]] ; then exit 1; fi


arn=`aws iam list-roles --output text | grep ${STORE_FUNCTION_ROLE} | awk '{print $2}'`
sed  "s=.*Role: \[ ROLE_ARN \].*=      Role: ${arn}=" ${this_folder}/_template.yaml | \
    sed  "s=.*TENANT: \[ TENANT \].*=          TENANT: ${TENANT}=" | \
    sed  "s=.*STAGE: \[ STAGE \].*=          STAGE: ${STAGE}=" | \
    sed  "s=.*ENV: \[ ENV \].*=          ENV: ${ENV}=" | \
    sed  "s=.*DB_API_REGION: \[ DB_API_REGION \].*=          DB_API_REGION: ${DB_API_REGION}=" | \
    sed  "s=.*ENTITIES: \[ ENTITIES \].*=          ENTITIES: ${ENTITIES}=" | \
    sed  "s=.*DB_API_ACCESS_KEY_ID: \[ DB_API_ACCESS_KEY_ID \].*=          DB_API_ACCESS_KEY_ID: ${DB_API_ACCESS_KEY_ID}=" | \
    sed  "s=.*DB_API_ACCESS_KEY: \[ DB_API_ACCESS_KEY \].*=          DB_API_ACCESS_KEY: ${DB_API_ACCESS_KEY}=" | \
    sed  "s=.*OWNER_ACCOUNT: \[ OWNER_ACCOUNT \].*=          OWNER_ACCOUNT: ${OWNER_ACCOUNT}=" > ${parent_folder}/src/template.yaml

cd ${SRC_DIR}

debug "...building src..."
sam build --use-container
__r=$?
if [[ ! "$__r" -eq "0" ]] ; then err "could not build src" && exit 1; fi


debug "...create and deploy built src to functions bucket: ${FUNCTION_BUCKET}..."
createBucket ${FUNCTION_BUCKET}
__r=$?
if [[ ! "$__r" -eq "0" ]] ; then err "could not create bucket" && exit 1; fi


debug "...packaging api..."
sam package --output-template-file ${SRC_DIR}/packaged.yaml --s3-bucket ${FUNCTION_BUCKET}
__r=$?
if [[ ! "$__r" -eq "0" ]] ; then err "could not package the api" && exit 1; fi

debug "...deploying api..."
sam deploy --template-file ${SRC_DIR}/packaged.yaml --stack-name ${API_STACK} --capabilities CAPABILITY_IAM --region ${REGION}
__r=$?
if [[ ! "$__r" -eq "0" ]] ; then err "could not deploy the api" && exit 1; fi

cd ${this_folder}

debug "get API endpoint"
API_ENDPOINT=$(aws cloudformation describe-stacks --stack-name ${API_STACK} --query 'Stacks[0].Outputs[0].OutputValue')
debug "removing quotes"
API_ENDPOINT=$(sed -e 's/^"//' -e 's/"$//' <<< ${API_ENDPOINT})
info "api: $API_ENDPOINT"
echo "$API_ENDPOINT" > ${parent_folder}/$API_URL_FILE


cd $_pwd

debug "...api build done."
