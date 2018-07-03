kubectl create -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml

kubectl describe services kubernetes-dashboard --namespace=kube-system

kubectl proxy --address 0.0.0.0 --port 8001 --accept-hosts='^*$' &