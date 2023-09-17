# KNative Sample

This is a sample that uses
[KNative](https://knative.dev/)
and [Cloud Events](https://cloudevents.io/)
(with the [.NET SdK](https://github.com/cloudevents/sdk-csharp/)).

## Requirements

1. Install Docker, Rancher or Podman;
2. Install k3d;
3. Install `libnss-myhostname` so that hosts `*.localhost` resolve to `127.0.0.1`;
4. Install k6 (only to test autoscaling).

## Setup

1. Run `./install.sh`
2. Source the configuration: `source use-cluster.sh`

## View it working

### Check Knative serving

```bash
# directly with an nginx reverse proxy into the cluster load balanced services
curl helloworld-csharp.hello-world.knative.knativetest.localhost
# or using the cluster load balanced services through metallb
KNATIVE_SERVING_IP=`kubectl get service --namespace knative-serving kourier -ojsonpath='{ .status.loadBalancer.ingress[0].ip }'`
curl -H 'Host: helloworld-csharp.hello-world.knative.knativetest.localhost' $KNATIVE_SERVING_IP
```

Or run the [serving.http](./requests/serving.http) file.

### Check Knative eventing

First you need to find the IP the ingress created for the KNative broker:

```bash
KNATIVE_EVENTING_IP=`kubectl get ingress --namespace knative-eventing knative-ingress -ojsonpath='{ .status.loadBalancer.ingress[0].ip }'`
```

Then, to run the producer:

```bash
dotnet run --project func/producer/ -- --ip $KNATIVE_EVENTING_IP --host broker-ingress.knativetest.localhost
```

Or run the [cloudevent.http](./requests/cloudevent.http) file.

The consumer will start and stop after 2 minutes without messages.

To view the pods and logs from the consumer:

```bash
kubectl get pod --namespace consumerns
kubectl logs --namespace consumerns --selector serving.knative.dev/service=consumer
```

## Tracing

Access the tracing dashboard at <http://jaeger.knativetest.localhost>

## Autoscale

Run  `./scale/run-web.sh` and in parallel `watch -n1 kubectl get pod --namespace hello-world` to see the pods autoscaling.

Run `./scale/run-inmemory-broker.sh`. Use `./scale/run-inmemory-broker.sh --help` to see options, for example:

```bash
# run for 120 seconds, waiting 50 miliseconds between messages, with 10 parallel users
./scale/run-inmemory-broker.sh --run-for 120 --delay 50 --parallel 10
```

## Endpoints

Jaeger: <http://jaeger.knativetest.localhost>
Knative eventing brokers:

* In memory broker: <http://broker-ingress.knativetest.localhost>

Knative Serving service endpoint (hello world function): <http://helloworld-csharp.hello-world.knative.knativetest.localhost>
Registry: <http://registry.knativetest.localhost:5000>

## Requests

See the [requests](./requests/) directory.

### Simulating a cloud event

See [cloudevent.http](./requests/cloudevent.http).

You can run it with Visual Studio Code and the
[Rest Client](https://marketplace.visualstudio.com/items?itemName=humao.rest-client)
extension (there are other tools that run this format, as well).
