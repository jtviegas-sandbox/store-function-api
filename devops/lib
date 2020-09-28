#@IgnoreInspection BashAddShebang
STATE_ACTIVE=ACTIVE
STATE_UPDATING=UPDATING
STATE_CREATING=CREATING
STATE_DELETING=DELETING
STATE_MISSING=MISSING

STATE_ACTIVE_CODE=9
STATE_UPDATING_CODE=7
STATE_CREATING_CODE=3
STATE_DELETING_CODE=2
STATE_MISSING_CODE=1

#LOG_TRACE=TRUE

debug(){
    local __msg="$1"
    echo "\n [DEBUG] `date` ... $__msg\n"
}

info(){
    local __msg="$1"
    echo "\n [INFO]  `date` ->>> $__msg\n"
}

warn(){
    local __msg="$1"
    echo "\n [WARN]  `date` *** $__msg\n"
}

err(){
    local __msg="$1"
    echo "\n [ERR]   `date` !!! $__msg\n"
}

goin(){
    if [[ ! -z $LOG_TRACE ]]; then
        local __msg="$1"
        local __params="$2"
        echo "\n [IN]    `date` ___ $__msg [$__params]\n"
    fi
}

goout(){
    if [[ ! -z $LOG_TRACE ]]; then
        local __msg="$1"
        local __outcome="$2"
        echo "\n [OUT]   `date` ___ $__msg [$__outcome]\n"
    fi
}

stat()
{
    goin "stat"
    
    info "current buckets:"
    aws s3 ls
    info "current tables:"
    aws dynamodb --output text list-tables
    info "current policies:"
    aws iam list-policies --output text | grep $PROJ
    
    goout "stat"
}

getTableState()
{
    goin "getTableState" $1
    local __r=${STATE_MISSING_CODE}
    local __table=$1
    local __s=`aws dynamodb describe-table --output text --table-name ${__table} | grep "^TABLE" | awk '{print $8}'`
    if [[ ! -z "$__s" ]]; then
        if [[ "$__s" = ${STATE_DELETING} ]]; then __r=${STATE_DELETING_CODE}; fi
        if [[ "$__s" = "$STATE_CREATING" ]]; then __r=${STATE_CREATING_CODE}; fi
        if [[ "$__s" = "$STATE_UPDATING" ]]; then __r=${STATE_UPDATING_CODE}; fi
        if [[ "$__s" = "$STATE_ACTIVE" ]]; then __r=${STATE_ACTIVE_CODE}; fi
    else
        __s=${STATE_MISSING}
    fi
    goout "getTableState" "$__r:$__s"
    return ${__r}
}

checkTableExistence()
{
    goin "checkTableExistence" $1
    local __r=1
    local __table=$1
    
    local __s=0
    while [[ "$__s" -ne "$STATE_MISSING_CODE" ]] && [[ "$__s" -ne "$STATE_ACTIVE_CODE" ]]
    do
        getTableState "$__table"
        __s=$?
        sleep 6
    done

    if [[ "$__s" -eq "$STATE_MISSING_CODE" ]]
    then
        __r=0
    fi
    
    goout "checkTableExistence" $__r
    return $__r
}

waitForNoTableState()
{
    goin "waitForNoTableState" $1
    local __table=$1
    
    local __s=0
    while [[ "$__s" -ne "$STATE_MISSING_CODE" ]]
    do
        getTableState "$__table"
        __s=$?
        sleep 6
    done
    goout "waitForNoTableState"
}

deleteTable()
{
    goin "deleteTable" $1
    local __r=0
    local __table=$1
    
    checkTableExistence "$__table"
    local __s=$?
    
    if [[ "$__s" -eq "0" ]]; then
        warn "table $__table is not there"
    else
        aws dynamodb delete-table --table-name $__table    
        __r=$?
        if [[ "$__r" -eq "0" ]]
        then 
            waitForNoTableState "$__table"
            info "table $__table not there anymore"
        fi
    fi
    goout "deleteTable" $__r
    return $__r
}
    

waitForTableState()
{
    goin "waitForTableState" $1
    local __table=$1
    local __state=$2
    
    local __s=0
    while [[ ! "$__s" -eq "$__state" ]]
    do
        getTableState "$__table"
        __s=$?
        sleep 6
    done
    
    goout "waitForTableState"
}

createTable()
{
    goin "createTable" $1
    local __r=0
    local __table=$1

    checkTableExistence "$__table"
    local __s=$?
    if [[ ! "$__s" -eq "0" ]]; then
        warn "table $__table already there"
        __r=0
    else
        aws dynamodb create-table --table-name $__table --attribute-definitions '[{"AttributeName":"id","AttributeType":"N"}]' --key-schema '[{"AttributeName":"id","KeyType":"HASH"}]'  --provisioned-throughput '{"ReadCapacityUnits":5, "WriteCapacityUnits":5}'
        
        # --global-secondary-indexes '[ { "IndexName": "IDX_NUM", "KeySchema":[ { "AttributeName": "number", "KeyType": "RANGE" } ] , "Projection":{"ProjectionType": "ALL"}, "ProvisionedThroughput":{"ReadCapacityUnits": 5, "WriteCapacityUnits":1} }, { "IndexName": "IDX_NUM", "KeySchema":[ { "AttributeName": "number", "KeyType": "RANGE" } ] , "Projection":{"ProjectionType": "ALL"}, "ProvisionedThroughput":{"ReadCapacityUnits": 5, "WriteCapacityUnits":1} } ]'
            
        # --local-secondary-indexes '[{"IndexName":"num", "KeySchema":[{"AttributeName":"n","KeyType":"RANGE"}], "Projection":{"ProjectionType":"ALL"}}]'
        #aws dynamodb create-table --table-name $__table --attribute-definitions AttributeName=id,AttributeType=S AttributeName=n,AttributeType=N --key-schema AttributeName=id,KeyType=HASH AttributeName=n,KeyType=RANGE --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 --local-secondary-indexes IndexName=N KeySchema=AttributeName=n,KeyType=number
        
        __r=$?
        if [[ "$__r" -eq "0" ]]; then
                waitForTableState "$__table" "$STATE_ACTIVE_CODE"
                info "created table $__table"
        else
            __r=1
        fi
    fi
    goout "createTable" "$__table:$__r"
    return $__r
}

createBucket()
{
    goin "createBucket" $1
    local __bucketName=$1
    __bucket="s3://$__bucketName"
    aws s3 ls | grep $__bucket
    local __r=$?
    if [[ "$__r" -eq "0" ]]
    then
        warn "found bucket $__bucket already created"
        __r=0
    else
        aws s3 mb $__bucket
        __r=$?
        if [[ ! "$__r" -eq "0" ]] ; then warn "could not create bucket $__bucket"; else info "created bucket $__bucket" ; fi
    fi
    goout "createBucket" "$__r"
    return $__r
}


deleteBucket()
{
    goin "deleteBucket" $1
    local __bucketName=$1
    __bucket="s3://$__bucketName"
    aws s3 ls | grep $__bucketName
    local __r=$?
    if [[ "$__r" -ne "0" ]]; then
        warn "couldn't find bucket $__bucket, not there"
        __r=0
    else
        aws s3 rb $__bucket --force
        __r=$?
        if [[ ! "$__r" -eq "0" ]] ; then warn "! could not delete bucket $__bucket !"; else info "deleted bucket $__bucket" ; fi
    fi
    goout "deleteBucket" $__r
    return $__r
}


createPolicyForBucket()
{
    goin "createPolicyForBucket" "$1 $2"

    local policy=$1
    local bucketName="$2"
    
    local store_buckets_resource="\"arn:aws:s3:::*\/*\",\"arn:aws:s3:::$bucketName\""
    sed  "s/.*\"Resource\": \[ XXXYYYZZZ \].*/\t\t\"Resource\": \[ $store_buckets_resource \]/" $this_folder/$policy.policy > $this_folder/$policy.json
    aws iam create-policy --policy-name $policy --policy-document file://$this_folder/$policy.json
    local __r=$?
    if [[ ! "$__r" -eq "0" ]] ; then warn "could not create policy $policy"; else info "created policy $policy" ; fi
    rm $this_folder/${policy}.json

    goout "createPolicyForBucket" $__r
    return $__r
}

deletePolicy()
{
    goin "deletePolicy" $1
    local policy=$1
    
    __r=0
    arn=`aws iam list-policies --output text | grep ${policy} | awk '{print $2}'`
    if [[ -z "$arn" ]]
    then 
        warn "could not find policy arn for $policy"
        __r=1
    else
        for v in `aws iam list-policy-versions --policy-arn $arn --output text | awk '{print $4}'`; do
            aws iam delete-policy-version --policy-arn $arn --version-id $v
            #if [ ! "$?" -eq "0" ] ; then warn "could not delete policy $policy version $v" && cd $_pwd && return 1; else info "deleted policy $policy version $v" ; fi
            if [ ! "$?" -eq "0" ] ; then warn "could not delete policy $policy version $v"; else info "deleted policy $policy version $v" ; fi
        done
        aws iam delete-policy --policy-arn $arn
        if [[ ! "$?" -eq "0" ]] ; then warn "could not delete policy $policy"; else info "deleted policy $policy" ; fi
    fi
    goout "deletePolicy" ${__r}
    return $__r
}

createPolicyForBucketAndTable()
{
    goin "createPolicyForBucketAndTable" "$1 $2"
    local __r=0
    local policy=$1
    local bucket=$2
    local table=$3
    
    sed  "s/.*\"Resource\": \[ XXXXXX \].*/\t\t\"Resource\": \[ \"arn:aws:s3:::$bucket\" \]/" $this_folder/$policy.policy > $this_folder/$policy.2
    local arn=`aws dynamodb describe-table --output text --table-name $table | grep arn.*$t | awk '{print $4}'`
    arn=`echo $arn  | sed "s/\//\\//g"`
    sed  "s=.*\"Resource\": \[ YYYYYY \].*=\t\t\"Resource\": \[ \"$arn\" \]=" $this_folder/$policy.2 > $this_folder/$policy.json
    rm $this_folder/${policy}.2
    
    aws iam create-policy --policy-name $policy --policy-document file://$this_folder/$policy.json
    __r=$? 
    if [[ ! "$__r" -eq "0" ]] ; then error "could not create policy $policy"; else info "created policy $policy" ; fi
    rm $this_folder/${policy}.json

    goout "createPolicyForBucketAndTable" $__r
    return $__r
}

createGroup()
{
    goin "createGroup" "$1"
    local __r=0
    local __group=$1
    
    aws iam --output text list-groups | grep $__group
    __r=$?
    if [ "$__r" -eq "0" ]
    then
        warn "found group $__group already created"
        __r=0
    else
        aws iam create-group --group-name $__group
        __r=$?
        if [ ! "$__r" -eq "0" ] ; then warn "could not create group $__group"; else info "created group $__group" ; fi
    fi
    
    goout "createGroup" $__r
    return $__r
}

deleteGroup()
{
    goin "deleteGroup" $1
    local __r=0
    local __group=$1
    
    aws iam list-groups --output=text | grep __group
    if [ "$__r" -ne "0" ]; then
        warn "couldn't find goup $__group, not there"
        __r=0
    else
        aws iam delete-group --group-name $__group
        __r=$?
        if [ ! "$__r" -eq "0" ] ; then warn "! could not delete group $__group!"; else info "deleted group $__group" ; fi
    fi
    goout "deleteGroup" $__r
    return $__r
}


createUser()
{
    goin "createUser" "$1"
    local __r=0
    local __user=$1
    
    aws iam create-user --user-name $__user
    __r=$?
    if [ ! "$__r" -eq "0" ] ; then 
        warn "could not create user $__user"
    else 
        info "created user $__user"
        aws iam create-login-profile --user-name $__user --password p4ssw0rd --password-reset-required
        __r=$?
        if [ ! "$__r" -eq "0" ] ; then warn "! could not create profile for user $__user!"; else info "profile created for user $__user" ; fi
    fi
 
    goout "createUser" $__r
    return $__r
}

deleteUser()
{
    goin "deleteUser" $1
    local __user=$1
    local __r=0
    
    aws iam delete-login-profile --user-name $__user
    __r=$?
    if [ ! "$__r" -eq "0" ] ; then warn "! could not delete user $__user profile !"; else info "deleted user $__user profile" ; fi
    aws iam delete-user --user-name $__user
    __r=$?
    if [ ! "$__r" -eq "0" ] ; then warn "! could not delete user $__user !"; else info "deleted user $__user" ; fi

    goout "deleteUser" $__r
    return $__r
}

attachPolicyToGroup()
{
    goin "attachPolicyToGroup" "$1 $2"
    local __policy=$1
    local __group=$2
    local __r=0
    
    local arn=`aws iam list-policies --output text | grep $__policy | awk '{print $2}'`
    if [ -z "$arn" ]
    then 
        warn "could not find policy arn for name: $__policy"
        __r=1
    else
        aws iam attach-group-policy --policy-arn $arn --group-name $__group
        __r=$?
        if [ ! "$__r" -eq "0" ] ; then warn "! could not attach group $__group to policy $__policy !"; else info "attached group $__group to policy $__policy" ; fi
    fi
 
    goout "attachPolicyToGroup" $__r
    return $__r
}

dettachPolicyFromGroup()
{
    goin "dettachPolicyFromGroup" "$1 $2"
    local __policy=$1
    local __group=$2
    local __r=0
    
    local arn=`aws iam list-policies --output text | grep $__policy | awk '{print $2}'`
    if [ -z "$arn" ]
    then 
        warn "could not find policy arn for name: $__policy"
        __r=1
    else
        aws iam detach-group-policy --group-name $__group --policy-arn $arn
         __r=$?
        if [ ! "$__r" -eq "0" ] ; then warn "! could not dettach group $__group from policy $__policy !"; else info "dettached group $__group from policy $__policy" ; fi
    fi

    goout "dettachPolicyFromGroup" $__r
    return $__r
}

addUserToGroup()
{
    goin "addUserToGroup" "$1 $2"
    local __user=$1
    local __group=$2
    local __r=0
    
    aws iam add-user-to-group --user-name $__user --group-name $__group
    __r=$?
    if [ ! "$__r" -eq "0" ] ; then warn "! could not add user $__user to $__group !"; else info "added user $__user to group $__group" ; fi
    
    goout "addUserToGroup" $__r
    return $__r
}

removeUserFromGroup()
{
    goin "removeUserFromGroup" "$1 $2"
    local __user=$1
    local __group=$2
    local __r=0
    
    aws iam remove-user-from-group --user-name $__user --group-name $__group
    __r=$?
    if [ ! "$__r" -eq "0" ] ; then warn "! could not remove user $__user from $__group !"; else info "removed user $__user from group $__group" ; fi
    
    goout "removeUserFromGroup" $__r
    return $__r
}

createRole()
{
    goin "createRole" "$1 $2"
    local __r=0
    local __role=$1
    local __role_policy_doc=$2
    
    aws iam create-role --role-name $__role --assume-role-policy-document file://$__role_policy_doc
    __r=$?
    if [ ! "$__r" -eq "0" ] ; then 
        warn "could not create role $__role"
    else 
        info "created role $__role"
    fi
 
    goout "createRole" $__r
    return $__r
}

deleteRole()
{
    goin "deleteRole" "$1"
    local __r=0
    local __role=$1
    
    aws iam delete-role --role-name $__role 
    __r=$?
    if [ ! "$__r" -eq "0" ] ; then 
        warn "could not delete role $__role"
    else 
        info "deleted role $__role"
    fi
 
    goout "deleteRole" $__r
    return $__r
}

attachRoleToPolicy()
{
    goin "attachRoleToPolicy" "$1 $2"
    local __role=$1
    local __policy=$2
    local __r=0
    
    local arn=`aws iam list-policies --output text | grep $__policy | awk '{print $2}'`
    if [ -z "$arn" ]
    then 
        warn "could not find policy arn for name: $__policy"
        __r=1
    else
        aws iam attach-role-policy --policy-arn $arn --role-name $__role
        __r=$?
        if [ ! "$__r" -eq "0" ] ; then warn "! could not attach role $__role to policy $_policy !"; else info "attached role $__role to policy $__policy" ; fi
    fi
 
    goout "attachRoleToPolicy" $__r
    return $__r
}

detachRoleFromPolicy()
{
    goin "detachRoleFromPolicy" "$1 $2"
    local __role=$1
    local __policy=$2
    local __r=0
    
    local arn=`aws iam list-policies --output text | grep $__policy | awk '{print $2}'`
    if [ -z "$arn" ]
    then 
        warn "could not find policy arn for name: $__policy"
        __r=1
    else
        aws iam detach-role-policy --policy-arn $arn --role-name $__role
        __r=$?
        if [ ! "$__r" -eq "0" ] ; then warn "! could not detach role $__role from policy $__policy !"; else info "detached role $__role from policy $__policy" ; fi
    fi

    goout "detachRoleFromPolicy" $__r
    return $__r
}


createFunction()
{
    goin "createFunction" "$1 $2 $3 $4 $5 $6 $7"
    local __r=0
    local __function=$1
    local __role=$2
    local __role_policy_doc=$2
    local __zip=$3
    local __handler=$4
    local __runtime=$5
    local __timeout=$6
    local __memory=$7

    local arn=`aws iam list-roles --output text | grep $__role | awk '{print $2}'`
    if [ -z "$arn" ]
    then 
        warn "could not find role arn for name: $__role"
        __r=1
    else
        # echo "aws lambda create-function --function-name $__function --zip-file fileb://$__zip --handler $__handler --runtime $__runtime --role $arn --timeout $__timeout --memory-size $__memory"
        aws lambda create-function --function-name $__function --zip-file fileb://$__zip --handler $__handler --runtime $__runtime --role $arn --timeout $__timeout --memory-size $__memory
        __r=$?
        if [ ! "$__r" -eq "0" ] ; then warn "! could not create function $__function !"; else info "created function $__function" ; fi
    fi

    goout "createFunction" $__r
    return $__r
}

deleteFunction()
{
    goin "deleteFunction" "$1"
    local __r=0
    local __function=$1
    
    aws lambda delete-function --function-name $__function
    __r=$?
    if [ ! "$__r" -eq "0" ] ; then 
        warn "could not delete function $__function"
    else 
        info "deleted function $__function"
    fi
 
    goout "deleteFunction" $__r
    return $__r
}

addPermissionToFunction()
{
    goin "addPermissionToFunction" "$1 $2 $3 $4 $5 $6"
    local __function=$1
    local __principal=$2
    local __statement_id=$3
    local __action=$4
    local __source_arn=$5
    local __source_account=$6
    
    local __r=0
    aws lambda add-permission --function-name $__function --principal $__principal --statement-id $__statement_id --action $__action --source-arn $__source_arn 
    #--source-account $__source_account
    __r=$?
    if [ ! "$__r" -eq "0" ] ; then warn "! could not setup permissions for function $__function !"; else info "created permissions for function $__function" ; fi
 
    goout "addPermissionToFunction" $__r
    return $__r
}


removePermissionFromFunction()
{
    goin "removePermissionFromFunction" "$1 $2"
    local __r=0
    local __function=$1
    local __statement_id=$2
    
    aws lambda remove-permission --function-name ${__function} --statement-id ${__statement_id}
    __r=$?
    if [[ ! "$__r" -eq "0" ]] ; then
        warn "could not remove permission from function $__function"
    else 
        info "removed permission from function $__function"
    fi
 
    goout "removePermissionFromFunction" $__r
    return $__r
}

createPolicy()
{
    goin "createPolicy" "$1 $2"

    local _name=$1
    local _spec="$2"
    
    echo "$_spec" > $this_folder/$_name.json
    aws iam create-policy --policy-name $_name --policy-document file://$this_folder/${_name}.json
    local __r=$?
    if [[ ! "$__r" -eq "0" ]] ; then warn "could not create policy $_name"; else info "created policy $_name" ; fi
    rm $this_folder/${_name}.json

    goout "createPolicy" $__r
    return $__r
}

buildPolicy()
{
    #goin "buildPolicy" "$1 $2 $3"
    local __r=0
    local __effect=$1
    local __actions=$2
    local __resources=$3
    
    local _spec="{\"Version\": \"2012-10-17\", \"Statement\": [{\"Effect\":"
    _spec="$_spec \"$__effect\""
    
    local _actions_str=
    for _action in $(echo ${__actions} | tr "," "\n")
    do
        if [[ -z ${_actions_str} ]]; then
            _actions_str="\"$_action\""
        else
            _actions_str="$_actions_str,\"$_action\""
        fi
    done
    
    local _resources_str=
    if [[ -z ${__resources} ]]; then
        _resources_str="\"*\""
    else
        for _resource in $(echo ${__resources} | tr "," "\n")
        do
            if [[ -z ${_resources_str} ]]; then
                _resources_str="\"$_resource\""
            else
                _resources_str="$_resources_str,\"$_resource\""
            fi
        done
    fi
    
    _spec="$_spec, \"Action\": [$_actions_str], \"Resource\": [$_resources_str]}]}" 
 
    #goout "buildPolicy" "$_spec"
    echo "$_spec"
}

deleteStack()
{
    goin "deleteStack" "$1"
    local __r=0
    local __stack=$1
    
    aws cloudformation delete-stack --stack-name $__stack
    __r=$?
    if [[ ! "$__r" -eq "0" ]] ; then
        warn "could not delete stack $__stack"
    else 
        info "deleted stack $__stack"
    fi
 
    goout "deleteStack" $__r
    return $__r
}

# result=$(buildPolicy Allow "iam:ChangePassword,s3:ListBucketByTags" "*")
# echo $result

# aws cloudformation describe-stacks --stack-name split4ever | grep "OUTPUTS.*partsApi" | awk '{print $13}'










