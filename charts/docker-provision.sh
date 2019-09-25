echo "Post-install job starting ......";
ADMIN_PASS_OLD="admin123";
CMD_GET_DOCKER_SCRIPT="curl -k -s -o /dev/null -w %{http_code} --max-time 5 -u admin:$ADMIN_PASS_OLD -XGET https://nexus.pluto.apim.ca:443/service/rest/v1/script/createDockerRepository";
CMD_GET_ADMIN_SCRIPT="curl -k -s -o /dev/null -w %{http_code} --max-time 5 -u admin:$ADMIN_PASS_OLD -XGET https://nexus.pluto.apim.ca:443/service/rest/v1/script/changeAdminPassword";
CMD_CHECK_DOCKER_REPO="curl -k -s --max-time 5 -u admin:$ADMIN_PASS_OLD -XGET https://nexus.pluto.apim.ca:443/service/rest/v1/repositories";
CMD_DELETE_REPO_SCRIPT="curl -k -s -o /dev/null -w %{http_code} --max-time 5 -u admin:$ADMIN_PASS_OLD -XDELETE https://nexus.pluto.apim.ca:443/service/rest/v1/script/createDockerRepository";
CMD_DELETE_ADMIN_SCRIPT="curl -k -s -o /dev/null -w %{http_code} --max-time 5 -u admin:7layer -XDELETE https://nexus.pluto.apim.ca:443/service/rest/v1/script/changeAdminPassword";
HTTP_CODE_GET=0;
HTTP_CODE_ADD=0;
HTTP_CODE_RUN=0;
HTTP_CODE_DEL=0;
NEXUS_READY=0;
Retries=0;
while [[ $Retries -lt 120 ]];
    do HTTP_CODE_GET=$($CMD_GET_DOCKER_SCRIPT);
    [[ $HTTP_CODE_GET == "200" ]] || [[ $HTTP_CODE_GET == "404" ]] && NEXUS_READY=1 && break;
    echo "Waiting for nexus ingress to be ready ......";
    sleep 15;
    Retries=$( expr $Retries + 1 );
done;
if [[ $NEXUS_READY ==  "0" ]];
then echo "Nexus ingress is NOT ready ......";
else
    echo "Nexus ingress is now ready ......";
    REPO_RES="$($CMD_CHECK_DOCKER_REPO)";
    REPO_EXISTS=$(echo $REPO_RES | grep repository/docker-hosted | wc -l);
    if [[ "$REPO_EXISTS" == "0" ]] && [[ $HTTP_CODE_GET == "404" ]];
    then
        Retries=0;
        while [[ $Retries -lt 15 ]];
            do HTTP_CODE_ADD="$(curl -s -o /dev/null -w ''%{http_code}'' --max-time 5 --header 'Content-Type:application/json' -u admin:$ADMIN_PASS_OLD -XPOST https://nexus.pluto.apim.ca:443/service/rest/v1/script --data '{"name":"createDockerRepository","content":"import org.sonatype.nexus.blobstore.api.BlobStoreManager;import org.sonatype.nexus.repository.storage.WritePolicy;repository.createDockerHosted('"'"'docker-hosted'"'"',5003,null,BlobStoreManager.DEFAULT_BLOBSTORE_NAME,false,true,WritePolicy.ALLOW)","type":"groovy"}')";
            [[ $HTTP_CODE_ADD == "204" ]] && break;
            sleep 5;
            Retries=$( expr $Retries + 1 );
        done;
        if [[ $HTTP_CODE_ADD == "204" ]];
        then echo "createDockerRepository script uploaded ......";
        else echo "Failed to upload createDockerRepository script, HTTP code is $HTTP_CODE_ADD ......";
        fi;
    elif [[ $HTTP_CODE_GET == "200" ]];
        then echo "createDockerRepository script already exists ......";
    elif [[ "$REPO_EXISTS" == "1" ]];
        then echo "Docker repo alrady exists ......";
    else echo "Can not add or find createDockerRepository script ......";
    fi;
    if [[ "$REPO_EXISTS" == "0" ]];
    then
        Retries=0;
        while [[ $Retries -lt 5 ]];
            do HTTP_CODE_RUN="$(curl -k -s -o /dev/null -w ''%{http_code}'' --max-time 5 --header 'Content-Type:text/plain' --header 'Content-Length:0' -u admin:$ADMIN_PASS_OLD -XPOST https://nexus.pluto.apim.ca:443/service/rest/v1/script/createDockerRepository/run)";
            [[ $HTTP_CODE_RUN == "200" ]] && break;
            sleep 5;
            Retries=$( expr $Retries + 1 );
        done;
        if [[ $HTTP_CODE_RUN == "200" ]];
        then echo "createDockerRepository script executed ......";
        else echo "Failed to execute createDockerRepository script, HTTP code is $HTTP_CODE_RUN ......";
        fi;
    fi;
    if [[ $HTTP_CODE_ADD == "204" ]];
    then
        Retries=0;
        while [[ $Retries -lt 5 ]];
            do HTTP_CODE_DEL=$($CMD_DELETE_REPO_SCRIPT);
            [[ $HTTP_CODE_DEL == "204" ]] && break;
            sleep 5;
            Retries=$( expr $Retries + 1 );
        done;
        if [[ $HTTP_CODE_DEL == "204" ]];
        then echo "createDockerRepository script deleted ......";
        else echo "Failed to delete createDockerRepository script, HTTP code is $HTTP_CODE_DEL ......";
        fi;
    fi;
    HTTP_CODE_GET=0;
    HTTP_CODE_ADD=0;
    HTTP_CODE_RUN=0;
    HTTP_CODE_DEL=0;
    HTTP_CODE_GET=$($CMD_GET_ADMIN_SCRIPT);
    if [[ $HTTP_CODE_GET == "404" ]];
    then
        Retries=0;
        while [[ $Retries -lt 5 ]];
            do HTTP_CODE_ADD="$(curl -s -o /dev/null -w ''%{http_code}'' --max-time 5 --header 'Content-Type:application/json' -u admin:$ADMIN_PASS_OLD -XPOST https://nexus.pluto.apim.ca:443/service/rest/v1/script --data '{"name":"changeAdminPassword","content":"security.securitySystem.changePassword('"'"'admin'"'"','"'"'7layer'"'"')","type":"groovy"}')";
            [[ $HTTP_CODE_ADD == "204" ]] && break;
            sleep 5;
            Retries=$( expr $Retries + 1 );
        done;
        if [[ $HTTP_CODE_ADD == "204" ]];
        then echo "changeAdminPassword script uploaded ......";
        else echo "Failed to upload changeAdminPassword script, HTTP code is $HTTP_CODE_ADD ......";
        fi;
    elif [[ $HTTP_CODE_GET == "200" ]];
    then echo "changeAdminPassword script already exists ......";
    fi;
    if [[ $HTTP_CODE_GET == "200" ]] || [[ $HTTP_CODE_ADD == "204" ]];
    then
        Retries=0;
        while [[ $Retries -lt 5 ]];
            do HTTP_CODE_RUN="$(curl -k -s -o /dev/null -w ''%{http_code}'' --max-time 5 --header 'Content-Type:text/plain' --header 'Content-Length:0' -u admin:$ADMIN_PASS_OLD -XPOST https://nexus.pluto.apim.ca:443/service/rest/v1/script/changeAdminPassword/run)";
            [[ $HTTP_CODE_RUN == "200" ]] && break;
            sleep 5;
            Retries=$( expr $Retries + 1 );
        done;
        if [[ $HTTP_CODE_RUN == "200" ]];
        then echo "changeAdminPassword script executed ......";
        else echo "Failed to execute changeAdminPassword script, HTTP code is $HTTP_CODE_RUN ......";
        fi;
    else echo "changeAdminPassword Script not found and failed to upload ......";
    fi;
    if [[ $HTTP_CODE_ADD == "204" ]];
    then
        Retries=0;
        while [[ $Retries -lt 5 ]];
            do HTTP_CODE_DEL=$($CMD_DELETE_ADMIN_SCRIPT);
            [[ $HTTP_CODE_DEL == "204" ]] && break;
            sleep 5;
            Retries=$( expr $Retries + 1 );
        done;
        if [[ $HTTP_CODE_DEL == "204" ]];
        then echo "changeAdminPassword Script deleted ......";
        else echo "Failed to delete changeAdminPassword script, HTTP code is $HTTP_CODE_DEL ......";
        fi;
    fi;
    echo "Post-install job finished ......";
fi;