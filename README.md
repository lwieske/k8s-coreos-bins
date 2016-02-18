# Vagrant Kubernetes Cluster based on Binary Provisioning

Flow: kubernetes binaries (apiserver, controller, scheduler, proxy, kubelet) are
downloaded from the kubernetes release site and cached in the bin directory.
Then **vagrant up** takes over, rsyncs the binaries to the node vms, and
configures everything for the final call to **fleet start** to launch the
binaries on their corresponding nodes. They find each other to make a working
kubernetes cluster.

```
vagrant up --provider virtualbox
```

```                                                                       
┌─────────────────────────────────────────────────────────────────────────────---────────────┐
│                                  10.10.10                                                  │
└─────────┬────────────┬────────────┬────────────---──┬────────────┬────────────┬────────────┤
          │            │            │                 │            │            │            │
       .11│         .12│        .13 │             .101│        .102│        .103│        .104│
          │            │            │                 │            │            │            │
     ┌────┤       ┌────┤       ┌────┤            ┌────┤       ┌────┤       ┌────┤       ┌────┤
     │eth1│       │eth1│       │eth1│            │eth1│       │eth1│       │eth1│       │eth1│
┌────┴────┤  ┌────┴────┤  ┌────┴────┤    ┌───────┴─-──┤  ┌────┴────┤  ┌────┴────┤  ┌────┴────┤
│         │  │         │  │         │    │            │  │         │  │         │  │         │
│ etcd-01 │  │ etcd-02 │  │ etcd-03 │    │ node-01    │  │ node-02 │  │ node-03 │  │ node-04 │
│         │  │         │  │         │    │            │  │         │  │         │  │         │
│─────────│  │─────────│  │─────────│    │────────────│  │─────────│  │─────────│  │─────────│
│         │  │         │  │         │    │ kube       │  │ kube    │  │ kube    │  │ kube    │
│         │  │         │  │         │    │ master     │  │         │  │         │  │         │
│         │  │         │  │         │    │            │  │ minion  │  │ minion  │  │ minion  │
│         │  │         │  │         │    │────────────│  │─────────│  │─────────│  │─────────│
│         │  │         │  │         │    │ apiserver  │  │ proxy   │  │ proxy   │  │ proxy   │
│         │  │         │  │         │    │ controller │  │ kubelet │  │ kubelet │  │ kubelet │
│         │  │         │  │         │    │ scheduler  │  │         │  │         │  │         │
│         │  │         │  │         │    │────────────│  │─────────│  │─────────│  │─────────│
│         │  │         │  │         │    │ fleet      │  │ fleet   │  │ fleet   │  │ fleet   │
│─────────│  │─────────│  │─────────│    │────────────│  │─────────│  │─────────│  │─────────│
│ etcd    │  │ etcd    │  │ etcd    │    │ etcd       │  │ etcd    │  │ etcd    │  │ etcd    │
│         │  │         │  │         │    │            │  │         │  │         │  │         │
│ peer    │  │ peer    │  │ peer    │    │ proxy      │  │ proxy   │  │ proxy   │  │ proxy   │
└─────────┘  └─────────┘  └─────────┘    └────────────┘  └─────────┘  └─────────┘  └─────────┘
```

```
$ fleetctl --endpoint http://10.10.10.11:2379 list-machines
MACHINE		IP		METADATA
73b64ef0...	10.10.10.102	core=node,kube=minion
aac099ca...	10.10.10.103	core=node,kube=minion
e80687b8...	10.10.10.100	core=node,kube=master
edfd9bff...	10.10.10.101	core=node,kube=minion
$
```

```
$ fleetctl --endpoint http://10.10.10.11:2379 start kube/*.service
Unit apiserver.service inactive
Unit controller.service inactive
Unit kubelet.service
Unit proxy.service
Unit scheduler.service inactive
Triggered global unit kubelet.service start
Triggered global unit proxy.service start
Unit controller.service launched on e80687b8.../10.10.10.100
Unit apiserver.service launched on e80687b8.../10.10.10.100
Unit scheduler.service launched on e80687b8.../10.10.10.100
$
```

```
$ kubectl --server http://10.10.10.100:8080 cluster-info
Kubernetes master is running at http://10.10.10.100:8080
```
```
$ kubectl --server http://10.10.10.100:8080 get nodes
NAME           LABELS                                STATUS    AGE
10.10.10.101   kubernetes.io/hostname=10.10.10.101   Ready     3m
10.10.10.102   kubernetes.io/hostname=10.10.10.102   Ready     3m
10.10.10.103   kubernetes.io/hostname=10.10.10.103   Ready     3m
$
```

### Configuration (Head of Vagrantfile)

```
members = {
  #  Name     #, CPU,  RAM, 1ST_IP
  'etcd' => [ 3,   1,  256,     11 ],
  'node' => [ 4,   2, 2048,    100 ],
}
PREFIX   = "10.10.10"
IP_RANGE = "10.11.0.0/16"
```
