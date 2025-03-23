# AMF scaling hints

## Helpful links

**RedHat AMF scaling:** https://www.redhat.com/en/blog/autoscale-5g-core

**Session affinity:** https://pauldally.medium.com/session-affinity-and-kubernetes-proceed-with-caution-8e66fd5deb05

**HPA, possibly applicable to AMF:** https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/
- need to set resources.limits, resources.requests (see HPA  algorithm https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/#algorithm-details )

**Longhorn**
- set up: https://longhorn.io/docs/1.8.1/deploy/install/install-with-kubectl/
- create volumes: https://longhorn.io/docs/1.8.1/nodes-and-volumes/volumes/create-volumes/
                https://docs.k3s.io/storage

## Prepare AMF chart

### Prepare AMF deployment

Thgere are two options to use multiple AMF pod instances:

1. Fix the targeted number of instances in the chart
2. Set the required number of instances changing the Deploymet.spec.replicas property

To test one can start with option 1 as above. To this end, set Values.replicacount:2 (note: this requires ReadWriteMany PVC support)

### Prepare volume
This is required to guarantee all AMF pods use the same persistent volume


