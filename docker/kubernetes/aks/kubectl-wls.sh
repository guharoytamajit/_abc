#!/bin/sh

#Usage message
usage()
{
        echo 'Interactive:'
        echo '$ kubectl wls'
        echo " "
        echo 'Non-Interactive'
        echo '$ kubectl wls NODE'
        echo " "
        echo "Example: kubectl wls minikube"
        echo " "
        echo "If you are running wls as a script without krew"
        echo "./kubectl-wls"
        exit 0
}

if [ "$1" = "-h" ]
then
        usage
        exit 1
fi

#Check user input.
if [ -z "$1" ]; then
          kubectl get nodes
            read -p "Enter the node name: " NODENAME
            NODE=$NODENAME

    else
        NODE=$1
    fi

#windows function to ssh to linux nodes
LINUXNODES () {

    IMAGE="alpine"
    POD="$NODE-exec-$(env LC_CTYPE=C tr -dc a-z0-9 < /dev/urandom | head -c 6)"

    # Check the node existance
    kubectl get node "$NODE" >/dev/null || exit 1

    #nsenter JSON overrrides
    OVERRIDES="$(cat <<EOT
{
  "spec": {
    "nodeName": "$NODE",
    "hostPID": true,
    "containers": [
      {
        "securityContext": {
          "privileged": true
        },
        "image": "$IMAGE",
        "name": "nsenter",
        "stdin": true,
        "stdinOnce": true,
        "tty": true,
        "command": [ "nsenter", "--target", "1", "--mount", "--uts", "--ipc", "--net", "--pid", "--", "bash", "-l" ]
      }
    ]
  }
}
EOT
)"

echo "creating pod \"$POD\" on node \"$NODE\""
kubectl run --rm --image $IMAGE --overrides="$OVERRIDES" --generator=run-pod/v1 -ti "$POD"
}


#windows function to ssh to windows nodes
WINDOWSNODES () {

echo "SSH into windows VM"
read -p "Enter the windows node ssh user: " WINDOWSSSHUSER
    IMAGE="alpine"
    POD="$NODE-exec-$(env LC_CTYPE=C tr -dc a-z0-9 < /dev/urandom | head -c 6)"

    # Check the node existance and IP
    kubectl get nodes "$NODE" -o wide >/dev/null || exit 1
    WINNODEIP=$(kubectl get node $NODE --output=jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}')

    #nsenter JSON overrrides
    OVERRIDES="$(cat <<EOT
{
  "spec": {
    "hostPID": true,
    "nodeSelector": {
      "kubernetes.io/os": "linux"
      },
    "containers": [
      {
        "securityContext": {
          "privileged": true
        },
        "image": "$IMAGE",
        "name": "nsenter",
        "stdin": true,
        "stdinOnce": true,
        "tty": true,
        "command": [ "nsenter", "--target", "1", "--mount", "--uts", "--ipc", "--net", "--pid", "--", "ssh", "$WINDOWSSSHUSER@$WINNODEIP" ]
      }
    ]
  }
}
EOT
)"

echo "creating pod \"$POD\" for windows ssh"
kubectl run --rm --image $IMAGE --overrides="$OVERRIDES" --generator=run-pod/v1 -ti "$POD"
}

#Evaluate if windows node.
NODEOS=$(kubectl get node $NODE -o jsonpath="{.metadata.labels.\kubernetes\.io/os}")

if [ $NODEOS = "windows" ]
then
    WINDOWSNODES
else
    LINUXNODES
fi
