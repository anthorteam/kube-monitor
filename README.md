# Anthor Kube-Monitor

This repo uses [kube-prometheus](https://github.com/prometheus-operator/kube-prometheus/tree/release-0.8) 
to prepare the manifests for a Prometheus+Grafana monitoring solution. It builds the manifests with jsonnet.

To install this repo and compile the manifests, you should first install go and then install jb, gojsontoyaml and jsonnet.

To install jb, gojsontoyaml and jsonnet, run:

```
go get github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb
go get github.com/brancz/gojsontoyaml
go get github.com/google/go-jsonnet/cmd/jsonnet
```

Remember to add GOPATH to your PATH.

After jb is installed, get the dependencies with:

```
jb install github.com/prometheus-operator/kube-prometheus/jsonnet/kube-prometheus@release-0.8
```

And then build the manifests with:

```
./build.sh main.jsonnet
```
